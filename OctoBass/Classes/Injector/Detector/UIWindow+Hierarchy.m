//
//  UIWindow+Hierarchy.m
//  OctoBass
//

#import "UIWindow+Hierarchy.h"


@implementation UIWindow (Hierarchy)


- (UIView *)ob_viewAtPoint:(CGPoint)point {
    return [self hitTest:point withEvent:nil];
}


@end

