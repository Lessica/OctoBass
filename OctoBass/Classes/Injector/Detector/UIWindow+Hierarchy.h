//
//  UIWindow+Hierarchy.h
//  OctoBass
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (Hierarchy)


/**
 * Use -hitTest: to fetch the top-most view which accepts user interactions
 * at the point in the window's coordinates.
 *
 * @param point The point in the window's coordinates.
 *
 * @returns The top-most view which accepts user interactions
 */
- (UIView *)ob_viewAtPoint:(CGPoint)point;


@end

NS_ASSUME_NONNULL_END
