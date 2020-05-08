//
//  UIWebView+Inspector.m
//  OctoBass
//

#import "UIWebView+Inspector.h"
#import "CaptainHook.h"


// Declare a property for WKUserContentController
CHDeclareProperty(WKUserContentController, inspectorReportedHash);


@implementation UIWebView (Inspector)


- (NSString *)ob_inspectorReportedHash {
    return CHPropertyGetValue(WKUserContentController, inspectorReportedHash);
}

- (void)ob_setInspectorReportedHash:(NSString *)hash {
    CHPropertySetValue(WKUserContentController, inspectorReportedHash, hash, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end

