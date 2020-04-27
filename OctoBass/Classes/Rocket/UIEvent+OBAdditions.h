//
//  UIEvent+OBAdditions.h
//  OctoBass
//

#import <UIKit/UIKit.h>


// Exposes methods of UITouchesEvent so that the compiler doesn't complain
@interface UIEvent (OBAdditionsPrivateHeaders)
- (void)_addTouch:(UITouch *)touch forDelayedDelivery:(BOOL)arg2;
- (void)_clearTouches;
@end

@interface UIEvent (OBAdditions)
- (void)ob_addon_a:(NSArray <UITouch *> *)touches /* ob_setEventWithTouches */;
@end

