//
//  OBAVPlayerObserver.m
//  OctoBass
//
//  Created by Darwin on 5/15/20.
//

#import "OBAVPlayerObserver.h"
#import <AVFoundation/AVFoundation.h>
#import "OBViewEvents.h"
#import <math.h>


@implementation OBAVPlayerObserver

+ (instancetype)sharedObserver {
    static OBAVPlayerObserver *observer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        observer = [[OBAVPlayerObserver alloc] init];
    });
    return observer;
}


#pragma mark - Initializer

- (instancetype)init {
    self = [super init];
    if (self) {
        // There's no need to unregister these observers above iOS 9.
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}


#pragma mark - Notifications

- (void)playerItemDidPlayToEndTime:(NSNotification *)aNotification {
    
}


#pragma mark - KVO

- (void)addObservablePlayer:(AVPlayer *)player {
    // But, we have to unregister these observers after use.
    //[player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [player addObserver:self forKeyPath:@"timeControlStatus" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservablePlayer:(AVPlayer *)player {
    //[player removeObserver:self forKeyPath:@"status"];
    [player removeObserver:self forKeyPath:@"timeControlStatus"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayer *player = (AVPlayer *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        //AVPlayerStatus status = player.status;
    }
    
    else if ([keyPath isEqualToString:@"timeControlStatus"]) {
        
        NSString *type = @"AVPlayer";
        
        BOOL paused = YES;
        BOOL ended = YES;
        
        // Fallback on earlier versions
        if (player.rate > 0 && player.error == nil) {
            paused = NO;
            ended = NO;
        }
        else if (player.rate == 0) {
            if (CMTimeCompare(player.currentItem.currentTime, player.currentItem.duration) == 0) {
                paused = YES;
                ended = YES;
            } else {
                paused = YES;
                ended = NO;
            }
        }
        
        if (@available(iOS 10.0, *)) {
            if (player.timeControlStatus == AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate) {
                return;
            }
        }
        
        NSTimeInterval duration = CMTimeGetSeconds(player.currentItem.duration);
        NSTimeInterval currentTime = CMTimeGetSeconds(player.currentItem.currentTime);
        NSString *src = nil;
        if ([player.currentItem.asset isKindOfClass:[AVURLAsset class]]) {
            src = [[(AVURLAsset *)player.currentItem.asset URL] absoluteString];
        }
        
        NSMutableDictionary <NSString *, id> *userInfo = [NSMutableDictionary dictionaryWithDictionary:@{
            @"type": type,
            @"paused": @(paused),
            @"ended": @(ended),
            @"duration": @(duration),  // isnan(duration)
            @"currentTime": @(currentTime),
        }];
        if (src) { [userInfo setObject:src forKey:@"src"]; }
        
        // Post internal notification.
        [[NSNotificationCenter defaultCenter] postNotificationName:_$OBNotificationNameMediaStatus object:self userInfo:userInfo];
        
    }
    
}


@end

