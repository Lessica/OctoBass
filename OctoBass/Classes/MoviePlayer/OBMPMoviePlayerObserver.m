//
//  OBMPMoviePlayerObserver.m
//  OctoBass
//

#if ENABLE_MPMOVIEPLAYER
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

#import "OBMPMoviePlayerObserver.h"
#import <MediaPlayer/MediaPlayer.h>
#import "OBViewEvents.h"


@implementation OBMPMoviePlayerObserver

+ (instancetype)sharedObserver {
    static OBMPMoviePlayerObserver *observer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observer = [[OBMPMoviePlayerObserver alloc] init];
    });
    return observer;
}


#pragma mark - Initializer

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlaybackStateDidChange:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDurationAvailable:) name:MPMovieDurationAvailableNotification object:nil];
    }
    return self;
}


#pragma mark - Notification Dispatchers

- (void)moviePlayerPlaybackStateDidChange:(NSNotification *)aNotification {
    MPMoviePlayerController *playerCtrl = (MPMoviePlayerController *)aNotification.object;
    if ([playerCtrl isKindOfClass:[MPMoviePlayerController class]]) {
        [self notifyMoviePlayerPlaybackChanges:playerCtrl];
    }
}

- (void)movieDurationAvailable:(NSNotification *)aNotification {
    MPMoviePlayerController *playerCtrl = (MPMoviePlayerController *)aNotification.object;
    if ([playerCtrl isKindOfClass:[MPMoviePlayerController class]]) {
        [self notifyMoviePlayerPlaybackChanges:playerCtrl];
    }
}

- (void)notifyMoviePlayerPlaybackChanges:(MPMoviePlayerController *)playerCtrl {
    
    NSString *type = @"MPMoviePlayerController";
    
    BOOL paused = YES;
    BOOL ended = YES;
    switch (playerCtrl.playbackState) {
        case MPMoviePlaybackStatePlaying:
            paused = NO;
            ended = NO;
            break;
        case MPMoviePlaybackStateStopped:
            ended = YES;
            paused = YES;
            break;
        case MPMoviePlaybackStatePaused:
            paused = YES;
            ended = NO;
            break;
        default: break;
    }
    
    NSTimeInterval duration = playerCtrl.duration;
    NSTimeInterval currentTime = playerCtrl.currentPlaybackTime;
    NSString *src = [playerCtrl.contentURL absoluteString];
    
    NSMutableDictionary <NSString *, id> *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{
        @"type": type,
        @"paused": @(paused),
        @"ended": @(ended),
        @"duration": @(duration),
        @"currentTime": @(currentTime),
    }];
    if (src) { [userInfo setObject:src forKey:@"src"]; }
    
    // Post internal notification.
    [[NSNotificationCenter defaultCenter] postNotificationName:_$OBNotificationNameMediaStatus object:self userInfo:userInfo];
    
}


@end


#pragma clang diagnostic pop
#endif  // ENABLE_MPMOVIEPLAYER

