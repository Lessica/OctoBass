//
//  UIView+Screenshortr.h
//  OctoBass
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface UIView (Screenshortr)

- (UIImage *)ob_snapshotr;
- (UIImage *)ob_snapshotrInRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END

