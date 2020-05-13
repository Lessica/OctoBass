//
//  OBWKWebViewMsgProxy.m
//  OctoBass
//

#import "OBWKWebViewMsgProxy.h"
#import "WKUserContentController+Inspector.h"
#import "OBViewEvents.h"


@implementation OBWKWebViewMsgProxy


- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    
    // Event: report
    if ([message.name isEqualToString:_$proxyHandlerNameReport]) {
        NSString *evaluatedReport = (NSString *)message.body;
        if ([evaluatedReport isKindOfClass:[NSString class]] && evaluatedReport.length) {
            
            // Save reported hash to user content controller.
            [userContentController ob_setInspectorReportedHash:evaluatedReport];
            
#if DEBUG
            NSLog(@"%@", evaluatedReport);
#endif  // DEBUG
            
        }
    }
    
    
    // Event: notify media status
    else if ([message.name isEqualToString:_$proxyHandlerNameNotifyMediaStatus]) {
        NSDictionary <NSString *, id> *evaluatedVideoDetail = (NSDictionary <NSString *, id> *)message.body;
        if ([evaluatedVideoDetail isKindOfClass:[NSDictionary class]]) {
            
            // Save reported video detail dictionary to user content controller.
            [userContentController ob_setLastMediaStatusDictionary:evaluatedVideoDetail];
            
            // Send a global notification.
            [[NSNotificationCenter defaultCenter] postNotificationName:_$OBNotificationNameMediaStatus object:self userInfo:evaluatedVideoDetail];
            
        }
    }
    
}


@end

