//
//  WKUserContentController+Inspector.m
//  OctoBass
//

#import "WKUserContentController+Inspector.h"
#import "CaptainHook.h"


// Declare properties for WKUserContentController
CHDeclareProperty(WKUserContentController, inspectorReportedHash);
CHDeclareProperty(WKUserContentController, lastMediaStatusDictionary);


@implementation WKUserContentController (Inspector)


#pragma mark - CHProperties


- (nullable NSString *)ob_inspectorReportedHash {
    return CHPropertyGetValue(WKUserContentController, inspectorReportedHash);
}

- (void)ob_setInspectorReportedHash:(nullable NSString *)hash {
    CHPropertySetValue(WKUserContentController, inspectorReportedHash, hash, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSDictionary *)ob_lastMediaStatusDictionary {
    return CHPropertyGetValue(WKUserContentController, lastMediaStatusDictionary);
}

- (void)ob_setLastMediaStatusDictionary:(nullable NSDictionary *)dict {
    CHPropertySetValue(WKUserContentController, lastMediaStatusDictionary, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end

