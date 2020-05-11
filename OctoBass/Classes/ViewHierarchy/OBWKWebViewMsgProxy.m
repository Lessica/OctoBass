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
    
    NSString *evaluatedResult = (NSString *)message.body;
    if ([evaluatedResult isKindOfClass:[NSString class]] && evaluatedResult.length) {
        
        // Save reported hash to user content controller
        [userContentController ob_setInspectorReportedHash:evaluatedResult];
        
    }
    
}


@end

