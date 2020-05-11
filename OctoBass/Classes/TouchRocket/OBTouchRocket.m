//
//  OBTouchRocket.m
//  OctoBass
//

#import "OBTouchRocket.h"
#import "LoadableCategory.h"
#import "UIApplication+OBAdditions.h"
#import "UIEvent+OBAdditions.h"
#import "UITouch+OBAdditions.h"


static NSMutableArray <UITouch *> *_$allTouches = nil;

@implementation OBTouchRocket


+ (void)load
{
    _$allTouches = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < 100; i++) {
        UITouch *touch = [[UITouch alloc] initTouch];
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseEnded];
        [_$allTouches addObject:touch];
    }
}


+ (NSInteger)touchWithFinger:(NSInteger)finger atPoint:(CGPoint)point withPhase:(UITouchPhase)phase
{
    
    if (finger == 0) {
        finger = [self availableFinger];
        if (finger == 0) {
            return 0;
        }
    }
    
    finger = finger - 1;
    UITouch *touch = [_$allTouches objectAtIndex:finger];
    
    if (phase == UITouchPhaseBegan) {
        
        UIApplication *sharedApplication = [UIApplication sharedApplication];
        
        touch = nil;
        touch = [[UITouch alloc] initAtPoint:point inWindow:sharedApplication.keyWindow];
        
        /// Keyboard FIX: Artem Levkovich, ITRex Group: http://itrexgroup.com
        UIWindow *lastWindow = [sharedApplication.windows lastObject];
        CGRect keyboardFrame;
        if ([lastWindow isKindOfClass:NSClassFromString([NSString stringWithFormat:@"UI%@%@Window", @"Remote", @"Keyboard"])] && (CGRectContainsPoint(CGRectMake(0, sharedApplication.keyWindow.frame.size.height - keyboardFrame.size.height, sharedApplication.keyWindow.frame.size.width, keyboardFrame.size.height), point)))
        {
            touch = [[UITouch alloc] initAtPoint:point inWindow:lastWindow];
        }
        
        [_$allTouches replaceObjectAtIndex:finger withObject:touch];
        [touch setLocationInWindow:point];
        
    } else {
        
        [touch setLocationInWindow:point];
        [touch setPhaseAndUpdateTimestamp:phase];
        
    }
    
    UIEvent *event = [self eventWithTouches:_$allTouches];
    [[UIApplication sharedApplication] sendEvent:event];
    
    if ((touch.phase == UITouchPhaseBegan) || touch.phase == UITouchPhaseMoved) {
        [touch setPhaseAndUpdateTimestamp:UITouchPhaseStationary];
    }
    
    return (finger + 1);
    
}


+ (NSInteger)availableFinger
{
    
    NSInteger availableFingerID = 0;
    NSMutableArray *availableFingerIDs = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < _$allTouches.count - 50; i++) {
        
        UITouch *touch = [_$allTouches objectAtIndex:i];
        
        if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
            [availableFingerIDs addObject:@(i + 1)];
        }
        
    }
    
    availableFingerID = availableFingerIDs.count == 0 ? 0 : [[availableFingerIDs objectAtIndex:(arc4random() % availableFingerIDs.count)] integerValue];
    return availableFingerID;
    
}


+ (NSInteger)tapAtPoint:(CGPoint)point
{
    NSInteger finger = [self availableFinger];
    [self touchWithFinger:finger atPoint:point withPhase:UITouchPhaseBegan];
    [self touchWithFinger:finger atPoint:point withPhase:UITouchPhaseEnded];
    return finger;
}


#pragma mark - Private


+ (UIEvent *)eventWithTouches:(NSArray *)touches
{
    
    UIEvent *event = [[UIApplication sharedApplication] _touchesEvent];
    [event _clearTouches];
    [event ob_addon_a:touches];
    
    for (UITouch *aTouch in touches) {
        [event _addTouch:aTouch forDelayedDelivery:NO];
    }
    
    return event;
    
}


@end

