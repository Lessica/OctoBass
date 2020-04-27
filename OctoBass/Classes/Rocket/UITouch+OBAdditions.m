//
//  UITouch+OBAdditions.m
//  OctoBass
//

#import "UITouch+OBAdditions.h"
#import "LoadableCategory.h"
#import <objc/runtime.h>


MAKE_CATEGORIES_LOADABLE(UITouch_OBAdditions)


typedef struct {
    unsigned int _firstTouchForView:1;
    unsigned int _isTap:1;
    unsigned int _isDelayed:1;
    unsigned int _sentTouchesEnded:1;
    unsigned int _abandonForwardingRecord:1;
} UITouchFlags;



@implementation UITouch (OBAdditions)

- (instancetype)initInView:(UIView *)view;
{
    CGRect frame = view.frame;    
    CGPoint centerPoint = CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f);
    return [self initAtPoint:centerPoint inView:view];
}

- (instancetype)initAtPoint:(CGPoint)point inWindow:(UIWindow *)window
{
	self = [super init];
    
	if (self) {
        
        [self setWindow:window];
        [self _setLocationInWindow:point resetPrevious:YES];
        
        UIView *hitTestView = [window hitTest:point withEvent:nil];
        
        [self setView:hitTestView];
        [self setPhase:UITouchPhaseBegan];
        [self _setIsFirstTouchForView:YES];
        [self setIsTap:NO];
        [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
        if ([self respondsToSelector:@selector(setGestureView:)]) {
            [self setGestureView:hitTestView];
        }
        
        // Starting with iOS 9, internal IOHIDEvent must be set for UITouch object
        if (@available(iOS 9.0, *)) {
            [self ob_func_a];
        }
        
    }
    
	return self;
}

- (void)resetTouch
{
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    CGPoint point = CGPointMake(0, 0);
    
    [self setWindow:window];
    [self _setLocationInWindow:CGPointMake(0, 0) resetPrevious:YES];
    
    UIView *hitTestView = [window hitTest:point withEvent:nil];
    
    [self setView:hitTestView];
    [self setPhase:UITouchPhaseBegan];
    [self _setIsFirstTouchForView:YES];
    [self setIsTap:NO];
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
    if ([self respondsToSelector:@selector(setGestureView:)]) {
        [self setGestureView:hitTestView];
    }
    
    // Starting with iOS 9, internal IOHIDEvent must be set for UITouch object
    if (@available(iOS 9.0, *)) {
        [self ob_func_a];
    }
}

- (instancetype)initTouch
{
    self = [super init];
    
    if (self) {
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        CGPoint point = CGPointMake(0, 0);
        [self setWindow:window];
        
        [self _setLocationInWindow:point resetPrevious:YES];
        
        UIView *hitTestView = [window hitTest:point withEvent:nil];
        
        [self setView:hitTestView];
        [self setPhase:UITouchPhaseEnded];
        
        [self _setIsFirstTouchForView:YES];
        [self setIsTap:NO];
        [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
        if ([self respondsToSelector:@selector(setGestureView:)]) {
            [self setGestureView:hitTestView];
        }
        
        // Starting with iOS 9, internal IOHIDEvent must be set for UITouch object
        if (@available(iOS 9.0, *)) {
            [self ob_func_a];
        }
        
    }
    
    return self;
}

- (instancetype)initAtPoint:(CGPoint)point inView:(UIView *)view
{
    return [self initAtPoint:[view.window convertPoint:point fromView:view] inWindow:view.window];
}

- (void)setLocationInWindow:(CGPoint)location
{
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
    [self _setLocationInWindow:location resetPrevious:NO];
}

- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase
{
    [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
    [self setPhase:phase];
}


#pragma mark - Private

- (void)ob_func_a /* ob_setIOHIDEvent */
{
    IOHIDEventRef event = ob_func0(@[self]);
    [self _setHidEvent:event];
    CFRelease(event);
}

@end

