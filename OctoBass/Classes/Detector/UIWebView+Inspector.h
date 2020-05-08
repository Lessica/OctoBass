//
//  UIWebView+Inspector.h
//  OctoBass
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWebView (Inspector)

- (NSString *)ob_inspectorReportedHash;
- (void)ob_setInspectorReportedHash:(NSString *)hash;

@end

NS_ASSUME_NONNULL_END
