//
//  OBWKWebViewMsgProxy.m
//  OctoBass
//

#import "OBWKWebViewMsgProxy.h"
#import "WKUserContentController+Inspector.h"


@implementation OBWKWebViewMsgProxy


- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    // Message body should be a string.
    if (![message.body isKindOfClass:[NSString class]]) {
        return;
    }
    
    // Save reported hash to user content controller
    [userContentController ob_setInspectorReportedHash:(NSString *)message.body];
    
}


@end

