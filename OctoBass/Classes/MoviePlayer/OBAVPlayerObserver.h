//
//  OBAVPlayerObserver.h
//  OctoBass
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>


NS_ASSUME_NONNULL_BEGIN

/**
* A global playback status observer for AVPlayer.
*/
@interface OBAVPlayerObserver : NSObject

+ (instancetype)sharedObserver;


/**
 * Track specified AVPlayer instance.
 * @param player An AVPlayer instance.
 */
- (void)addObservablePlayer:(AVPlayer *)player;


/**
 * Stop tracking specified AVPlayer instance.
 * @param player The AVPlayer instance.
 */
- (void)removeObservablePlayer:(AVPlayer *)player;


@end

NS_ASSUME_NONNULL_END

