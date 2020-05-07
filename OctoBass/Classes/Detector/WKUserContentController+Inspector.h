//
//  WKUserContentController+Inspector.h
//  OctoBass
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKUserContentController (Inspector)

- (NSString *)ob_inspectorReportedHash;
- (void)ob_setInspectorReportedHash:(NSString *)hash;

@end

NS_ASSUME_NONNULL_END
