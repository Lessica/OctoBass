//
//  NativeMPViewController.m
//  OctoBassTests
//

#import "NativeMPViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "NativeMPView.h"


#define VIDEO_URL @"https://www.w3schools.com/html/mov_bbb.mp4"


@interface NativeMPViewControllerProxy : NSObject

@property (nonatomic, weak) NativeMPViewController *target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) NSTimer *timer;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTarget:(nonnull NativeMPViewController *)target selector:(nonnull SEL)selector userInfo:(nullable id)userInfo NS_DESIGNATED_INITIALIZER;

@end

@implementation NativeMPViewControllerProxy

- (instancetype)initWithTarget:(nonnull NativeMPViewController *)target selector:(nonnull SEL)selector userInfo:(nullable id)userInfo {
    self = [super init];
    if (self) {
        _target = target;
        _selector = selector;
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fire:) userInfo:userInfo repeats:YES];
        [_timer fire];
    }
    return self;
}

- (void)fire:(NSTimer *)timer {
    if (self.target) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.selector withObject:timer.userInfo];
#pragma clang diagnostic pop
    } else {
        [timer invalidate];
    }
}

@end


@interface NativeMPViewController ()

@property (nonatomic, strong) MPMoviePlayerController *movieController;
@property (nonatomic, strong) MPMoviePlayerViewController *extraMovieViewController;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *extraItem;
@property (nonatomic, weak) IBOutlet NativeMPView *mpPlayerView;
@property (nonatomic, weak) IBOutlet UIView *mpCoverView;
@property (nonatomic, weak) IBOutlet UILabel *extraHint;
@property (nonatomic, weak) IBOutlet UILabel *unsupportedHint;
@property (nonatomic, weak) IBOutlet UIButton *skipButton;

@property (nonatomic, strong) NativeMPViewControllerProxy *playbackObserver;
@property (nonatomic, assign) NSTimeInterval totalTime;

@end


@implementation NativeMPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13.0, *)) {
        [self.unsupportedHint setHidden:NO];
        [self.extraItem setEnabled:NO];
    } else {
        
        NSURL *movieURL = [NSURL URLWithString:VIDEO_URL];
        self.movieController = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
        self.movieController.shouldAutoplay = YES;
        self.movieController.controlStyle = MPMovieControlStyleNone;
        [self.movieController prepareToPlay];
        
        [self.movieController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.movieController.view setFrame:self.mpPlayerView.bounds];
        [self.mpPlayerView addSubview:self.movieController.view];
        [self.movieController play];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(durationAvailable:) name:MPMovieDurationAvailableNotification object:nil];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPause:)];
        [self.mpCoverView addGestureRecognizer:tapGesture];
        
        self.playbackObserver = [[NativeMPViewControllerProxy alloc] initWithTarget:self selector:@selector(updatePlaybackProgress:) userInfo:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.movieController pause];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Play only if needed.
    if (!self.presentedViewController) {
        [self.movieController play];
    }
}


#pragma mark - Fake Action

- (IBAction)downloadFromAppStore:(UIButton *)sender {
    [self.movieController pause];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://"] options:@{} completionHandler:^(BOOL success) {}];
}


#pragma mark - Play/Pause Gesture

- (void)playOrPause:(UITapGestureRecognizer *)gesture {
    if (self.movieController.playbackState == MPMusicPlaybackStatePlaying) {
        [self.movieController pause];
    } else {
        [self.movieController play];
    }
}


#pragma mark - Playback Observer

- (void)updatePlaybackProgress:(nullable id)userInfo {
    BOOL isInline      = self.presentedViewController == nil;
    int currentSeconds = (int)(isInline ? self.movieController.currentPlaybackTime : self.extraMovieViewController.moviePlayer.currentPlaybackTime);
    int totalSeconds   = (int)(isInline ? self.movieController.duration : self.extraMovieViewController.moviePlayer.duration);
    
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
}


#pragma mark - Notifications

- (void)loadStateDidChange:(NSNotification *)aNotification {
    MPMoviePlayerController *playerCtrl = (MPMoviePlayerController *)aNotification.object;
    switch (playerCtrl.loadState) {
        case MPMovieLoadStatePlayable: break;
        case MPMovieLoadStatePlaythroughOK: break;
        case MPMovieLoadStateStalled: break;
        default: break;
    }
}

- (void)playbackStateDidChange:(NSNotification *)aNotification {
    MPMoviePlayerController *playerCtrl = (MPMoviePlayerController *)aNotification.object;
    switch (playerCtrl.playbackState) {
        case MPMoviePlaybackStatePlaying: break;
        case MPMoviePlaybackStateStopped: break;
        case MPMoviePlaybackStatePaused: break;
        default: break;
    }
}

- (void)playbackDidFinish:(NSNotification *)aNotification {
    MPMoviePlayerController *playerCtrl = (MPMoviePlayerController *)aNotification.object;
    if (playerCtrl == self.movieController) {
        [playerCtrl pause];
        [playerCtrl setCurrentPlaybackTime:0.0];
    } else {
        // Do nothing.
    }
}

- (void)durationAvailable:(NSNotification *)aNotification {
    MPMoviePlayerController *playerCtrl = (MPMoviePlayerController *)aNotification.object;
    if (playerCtrl == self.movieController) {
        self.totalTime = playerCtrl.duration;
    }
}


#pragma mark - Navigation

- (IBAction)showInController:(UIBarButtonItem *)sender {
    [self.movieController pause];
    
    NSURL *movieURL = [NSURL URLWithString:VIDEO_URL];
    self.extraMovieViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];
    [self presentMoviePlayerViewControllerAnimated:self.extraMovieViewController];
    [self.extraMovieViewController.moviePlayer play];
}


#pragma mark - Private

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
}


@end

