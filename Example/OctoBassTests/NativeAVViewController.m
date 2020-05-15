//
//  NativeAVViewController.m
//  OctoBassTests
//

#import "NativeAVViewController.h"
#import "NativeAVView.h"


#define VIDEO_URL @"https://www.w3schools.com/html/mov_bbb.mp4"

@interface NativeAVViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *extraItem;
@property (nonatomic, weak) IBOutlet NativeAVView *avPlayerView;
@property (nonatomic, weak) IBOutlet UILabel *extraHint;
@property (nonatomic, weak) IBOutlet UIButton *skipButton;

@property (nonatomic, strong) AVPlayer      *avPlayer;
@property (nonatomic, strong) AVPlayerItem  *avPlayerItem;
@property (nonatomic, strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic, weak)   AVPlayer      *extraAVPlayer;
@property (nonatomic, strong) id             avPlayerMonitoringObserver;
@property (nonatomic, strong) id             extraAVPlayerMonitoringObserver;

@property (nonatomic, assign) CFTimeInterval totalTime;
@property (nonatomic, assign) CFTimeInterval extraTotalTime;

@end


@implementation NativeAVViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    NSURL *videoURL = [NSURL URLWithString:VIDEO_URL];
    self.avPlayerItem  = [AVPlayerItem playerItemWithURL:videoURL];
    self.avPlayer      = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    
    [self.avPlayerLayer setBackgroundColor:[UIColor blackColor].CGColor];
    [self.avPlayerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.avPlayerLayer setContentsScale:[UIScreen mainScreen].scale];
    
    [self.avPlayerView.layer addSublayer:self.avPlayerLayer];
    [self.avPlayerView setPlayerLayer:self.avPlayerLayer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause:)];
    [self.avPlayerView addGestureRecognizer:tapGesture];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.avPlayerItem removeObserver:self forKeyPath:@"status"];
    [self.avPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self stopMonitoringPlayback:self.avPlayer];
    
    [self.avPlayer pause];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.presentedViewController) {
        AVPlayerItem *playerItem = self.extraAVPlayer.currentItem;
        [playerItem removeObserver:self forKeyPath:@"status"];
        [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self stopMonitoringPlayback:self.extraAVPlayer];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.avPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.avPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [self beginMonitoringPlayback:self.avPlayer];
    
    // Play only if needed.
    if (!self.presentedViewController) {
        [self.avPlayer play];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.presentedViewController) {
        AVPlayerItem *playerItem = self.extraAVPlayer.currentItem;
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [self beginMonitoringPlayback:self.extraAVPlayer];
    }
}


#pragma mark - Fake Action

- (IBAction)downloadFromAppStore:(UIButton *)sender {
    [self.avPlayer pause];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://"] options:@{} completionHandler:^(BOOL success) {}];
}


#pragma mark - Play/Pause Gesture

- (void)playOrPause:(UITapGestureRecognizer *)gesture {
    if (self.avPlayer.rate > 0 && self.avPlayer.error == nil) {
        [self.avPlayer pause];
    } else {
        [self.avPlayer play];
    }
}


#pragma mark - Playback Notification

- (void)playerItemDidPlayToEndTime:(NSNotification *)aNotification {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)aNotification.object;
    BOOL isInline = playerItem == self.avPlayerItem;
    
    if (!isInline && self.presentedViewController) {
        // Stop video and dismiss extra player view controller.
        [self.extraAVPlayer pause];
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        // Seek video to its head.
        [self.avPlayer pause];
        [self.avPlayer seekToTime:CMTimeMakeWithSeconds(0.0, NSEC_PER_SEC)];
    }
    
}


#pragma mark - Playback Observer

- (void)beginMonitoringPlayback:(AVPlayer *)player {
    
    AVPlayerItem *playerItem = player.currentItem;
    
    id observer = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        
        BOOL isInline      = playerItem == self.avPlayerItem;
        int currentSeconds = (int)(playerItem.currentTime.value / playerItem.currentTime.timescale);
        int totalSeconds   = (int)(isInline ? self.totalTime : self.extraTotalTime);
        
        NSString *currentSecondsString = [self timeFormatted:currentSeconds];
        NSString *totalSecondsString   = [self timeFormatted:totalSeconds];
        NSLog(@"%@: %@ / %@", (isInline ? @"inline" : @"extra"), currentSecondsString, totalSecondsString);
        if (isInline) {
            [UIView performWithoutAnimation:^{
                [self.extraHint setText:[NSString stringWithFormat:@"Tap video to Play/Pause\n%@ / %@", currentSecondsString, totalSecondsString]];
                int secondsLeft = totalSeconds - currentSeconds;
                if (secondsLeft == 0) {
                    [self.skipButton setTitle:@"Skip Ads" forState:UIControlStateNormal];
                } else {
                    [self.skipButton setTitle:[NSString stringWithFormat:@"Skip Ads (%d)", secondsLeft] forState:UIControlStateNormal];
                }
                [self.skipButton layoutIfNeeded];
            }];
        }
        
    }];
    
    if (playerItem == self.avPlayerItem) {
        self.avPlayerMonitoringObserver = observer;
    } else {
        self.extraAVPlayerMonitoringObserver = observer;
    }
    
}

- (void)stopMonitoringPlayback:(AVPlayer *)player {
    
    if (player == self.avPlayer && self.avPlayerMonitoringObserver != nil) {
        [player removeTimeObserver:self.avPlayerMonitoringObserver];
        self.avPlayerMonitoringObserver = nil;
    }
    else if (player != self.avPlayer && self.extraAVPlayerMonitoringObserver != nil) {
        [player removeTimeObserver:self.extraAVPlayerMonitoringObserver];
        self.extraAVPlayerMonitoringObserver = nil;
    }
    
}


#pragma mark - Key/Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        //CFTimeInterval loadedTime = [self availableDurationWithplayerItem:playerItem];
        CFTimeInterval totalTime = CMTimeGetSeconds(playerItem.duration);
        // Video loaded
        if (playerItem == self.avPlayerItem) {
            self.totalTime = totalTime;
        } else {
            self.extraTotalTime = totalTime;
        }
    }
    
    else if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            // Ready to play
            if (playerItem == self.avPlayerItem) {
                // Play only if needed.
                if (!self.presentedViewController) {
                    [self.avPlayer play];
                }
            } else {
                [self.extraAVPlayer play];
            }
        } else {
            // Failed to load
        }
    }
    
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    id destCtrl = [segue destinationViewController];
    if ([destCtrl isKindOfClass:[AVPlayerViewController class]]) {
        
        AVPlayerViewController *ctrl = (AVPlayerViewController *)destCtrl;
        
        NSURL *videoURL = [NSURL URLWithString:VIDEO_URL];
        AVPlayer *player = [AVPlayer playerWithURL:videoURL];
        
        ctrl.player = player;
        ctrl.delegate = self;
        self.extraAVPlayer = player;
        
    }
}


#pragma mark - Private

- (NSTimeInterval)availableDurationWithplayerItem:(AVPlayerItem *)playerItem {
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];
    NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;
    return result;
}

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}


@end

