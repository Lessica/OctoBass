//
//  UIView+Hierarchy.h
//  OctoBass
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Hierarchy)


/**
 * Get all superviews in reversed hierarchy order.
 *
 * @returns All superviews in reversed hierarchy order. The first object is the view itself.
 */
- (NSArray <UIView *> *)ob_superviews;


@end

NS_ASSUME_NONNULL_END
