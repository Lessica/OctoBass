#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CaptainHook.h"
#import "NSString+Hashes.h"
#import "OBClassHierarchyDetector.h"
#import "OBWKWebViewMsgProxy.h"
#import "UIView+Description.h"
#import "UIView+Hierarchy.h"
#import "UIWebView+Description.h"
#import "UIWebView+Inspector.h"
#import "UIWindow+Hierarchy.h"
#import "WKUserContentController+Inspector.h"
#import "WKWebView+Description.h"
#import "MyCHHook.h"
#import "LoadableCategory.h"
#import "OBTouchRocket.h"
#import "ob_private.h"
#import "UIApplication+OBAdditions.h"
#import "UIEvent+OBAdditions.h"
#import "UITouch+OBAdditions.h"

FOUNDATION_EXPORT double OctoBassVersionNumber;
FOUNDATION_EXPORT const unsigned char OctoBassVersionString[];

