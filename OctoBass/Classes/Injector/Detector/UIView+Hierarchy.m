//
//  UIView+Hierarchy.m
//  OctoBass
//

#import "UIView+Hierarchy.h"


@implementation UIView (Hierarchy)


- (NSArray <UIView *> *)ob_superviews {
    
    NSMutableArray <UIView *> *superviews = [NSMutableArray arrayWithObject:self];
    
    UIView *view = self;
    while ((view = view.superview) != nil) {
        [superviews addObject:view];
        if ([view isKindOfClass:[UIWindow class]]) {
            break;
        }
    }
    
    return [superviews copy];
    
}


@end

