//
//  OBWKWebViewMsgProxy.h
//  OctoBass
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *_$proxyHandlerNameReport = @"_$webinspectord_report";
static NSString *_$proxyHandlerNameNotifyMediaStatus = @"_$webinspectord_notify_media_status";

@interface OBWKWebViewMsgProxy : NSObject <WKScriptMessageHandler>

@end

NS_ASSUME_NONNULL_END
