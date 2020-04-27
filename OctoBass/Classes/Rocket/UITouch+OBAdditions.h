//
//  UITouch+OBAdditions.h
//  OctoBass
//

#import <UIKit/UIKit.h>
#import "ob_private.h"


@interface UITouch ()

- (void)setWindow:(UIWindow *)window;
- (void)setView:(UIView *)view;
- (void)setTapCount:(NSUInteger)tapCount;
- (void)setIsTap:(BOOL)isTap;
- (void)setTimestamp:(NSTimeInterval)timestamp;
- (void)setPhase:(UITouchPhase)touchPhase;
- (void)setGestureView:(UIView *)view;
- (void)_setLocationInWindow:(CGPoint)location resetPrevious:(BOOL)resetPrevious;
- (void)_setIsFirstTouchForView:(BOOL)firstTouchForView;
- (void)_setHidEvent:(IOHIDEventRef)event;

@end

@interface UITouch (OBAdditions)

- (instancetype)initInView:(UIView *)view;
- (instancetype)initAtPoint:(CGPoint)point inView:(UIView *)view;
- (instancetype)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window;
- (instancetype)initTouch;
- (void)resetTouch;
- (void)setLocationInWindow:(CGPoint)location;
- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase;

@end

