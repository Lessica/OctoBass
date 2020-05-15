//
//  OBAVPlayerObserver.m
//  OctoBass
//
//  Created by Darwin on 5/15/20.
//

#import "OBAVPlayerObserver.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "OBViewEvents.h"


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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}


#pragma mark - Notifications

- (void)playerItemDidPlayToEndTime:(NSNotification *)aNotification {
    
}


#pragma mark - KVO

- (void)addObservableItem:(AVPlayerItem *)item {
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeObservableItem:(AVPlayerItem *)item {
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
}


@end

