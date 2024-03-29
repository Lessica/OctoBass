//
//  UIEvent+OBAdditions.m
//  OctoBass
//

#import "UIEvent+OBAdditions.h"
#import "LoadableCategory.h"
#import "ob_private.h"


MAKE_CATEGORIES_LOADABLE(UIEvent_OBAdditions)


//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface OBEventProxy : NSObject
{
@public
    unsigned int flags;
    unsigned int type;
    unsigned int ignored1;
    float x1;
    float y1;
    float x2;
    float y2;
    unsigned int ignored2[10];
    unsigned int ignored3[7];
    float sizeX;
    float sizeY;
    float x3;
    float y3;
    unsigned int ignored4[3];
}
@end

@implementation OBEventProxy
@end

typedef struct __GSEvent * GSEventRef;

@interface UIEvent (OBAdditionsMorePrivateHeaders)
- (void)_setGSEvent:(GSEventRef)event;
- (void)_setHIDEvent:(IOHIDEventRef)event;
- (void)_setTimestamp:(NSTimeInterval)timestemp;
@end

@implementation UIEvent (OBAdditions)

- (void)ob_addon_a:(NSArray <UITouch *> *)touches
{
    if (@available(iOS 8.0, *)) {
        [self ob_func_b:touches];
    } else {
        [self ob_func_c:touches];
    }
}

- (void)ob_func_c:(NSArray <UITouch *> *)touches /* ob_setGSEventWithTouches */
{
    UITouch *touch = touches[0];
    CGPoint location = [touch locationInView:touch.window];
    
    OBEventProxy *gsEventProxy = [[OBEventProxy alloc] init];
    gsEventProxy->x1 = location.x;
    gsEventProxy->y1 = location.y;
    gsEventProxy->x2 = location.x;
    gsEventProxy->y2 = location.y;
    gsEventProxy->x3 = location.x;
    gsEventProxy->y3 = location.y;
    gsEventProxy->sizeX = 1.0;
    gsEventProxy->sizeY = 1.0;
    gsEventProxy->flags = ([touch phase] == UITouchPhaseEnded) ? 0x1010180 : 0x3010180;
    gsEventProxy->type = 3001;
    
    [self _setGSEvent:(GSEventRef)gsEventProxy];
    [self _setTimestamp:(((UITouch*)touches[0]).timestamp)];
}

- (void)ob_func_b:(NSArray <UITouch *> *)touches /* ob_setIOHIDEventWithTouches */
{
    IOHIDEventRef event = ob_func0(touches);
    [self _setHIDEvent:event];
    CFRelease(event);
}

@end

