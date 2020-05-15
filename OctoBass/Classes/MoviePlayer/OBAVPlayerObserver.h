//
//  OBAVPlayerObserver.h
//  OctoBass
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
* A global playback status observer for AVPlayer.
*/
@interface OBAVPlayerObserver : NSObject

+ (instancetype)sharedObserver;

@end

NS_ASSUME_NONNULL_END

