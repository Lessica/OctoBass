//
//  OBMPMoviePlayerObserver.h
//  OctoBass
//

#if ENABLE_MPMOVIEPLAYER

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 * A global playback status observer for deprecated MPMoviePlayer.
 * Actually, MPMoviePlayer uses AVPlayer on newer iOS versions.
 */
@interface OBMPMoviePlayerObserver : NSObject

+ (instancetype)sharedObserver;

@end

NS_ASSUME_NONNULL_END


#endif  // ENABLE_MPMOVIEPLAYER

