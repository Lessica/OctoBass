//
//  UIView+Screenshortr.m
//  OctoBass
//

#import "UIView+Screenshortr.h"


@implementation UIView (Screenshortr)

- (UIImage *)ob_snapshotr {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, 0.0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

- (UIImage *)ob_snapshotrInRect:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0.0);
    [self drawViewHierarchyInRect:UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(-rect.origin.y, -rect.origin.x, rect.origin.y, rect.origin.x)) afterScreenUpdates:YES];
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}

@end

