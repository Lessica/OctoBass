//
//  WKUserContentController+Inspector.h
//  OctoBass
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKUserContentController (Inspector)

- (nullable NSString *)ob_inspectorReportedHash;
- (void)ob_setInspectorReportedHash:(nullable NSString *)hash;
- (nullable NSDictionary *)ob_lastMediaStatusDictionary;
- (void)ob_setLastMediaStatusDictionary:(nullable NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
