//
//  UIWebView+Inspector.m
//  OctoBass
//

#if ENABLE_UIWEBVIEW

#import "UIWebView+Inspector.h"
#import "CaptainHook.h"
#import "NSString+JavaScriptEscape.h"


// Declare properties for UIWebView
CHDeclareProperty(UIWebView, inspectorReportedHash);
CHDeclareProperty(UIWebView, lastMediaStatusDictionary);


@implementation UIWebView (Inspector)


#pragma mark - CHProperties


- (NSString *)ob_inspectorReportedHash {
    return CHPropertyGetValue(UIWebView, inspectorReportedHash);
}

- (void)ob_setInspectorReportedHash:(NSString *)hash {
    CHPropertySetValue(UIWebView, inspectorReportedHash, hash, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSDictionary *)ob_lastMediaStatusDictionary {
    return CHPropertyGetValue(UIWebView, lastMediaStatusDictionary);
}

- (void)ob_setLastMediaStatusDictionary:(nullable NSDictionary *)dict {
    CHPropertySetValue(UIWebView, lastMediaStatusDictionary, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


#pragma mark - JavaScript Payloads


- (nullable NSString *)ob_getElementSelectorByViewPortPoint:(CGPoint)point shouldHighlight:(BOOL)highlight
{
    
    if ([self isLoading]) {
        return nil;
    }
    
    NSString *payload = [NSString stringWithFormat:@"var el = document.elementFromPoint(%f, %f); var sel = window._$getElementSelector(el); %@ sel;", point.x, point.y, (highlight ? @"window._$highlightElement(el);" : @"")];
    
    NSString *result = [self ob_evaluateJavaScript:payload shouldParseJSON:NO];
    if (![result isKindOfClass:[NSString class]] || !result.length) {
        return nil;
    }
    
    return result;
    
}


- (CGRect)ob_getViewPortRectByElementSelector:(NSString *)elementSelector shouldScrollTo:(BOOL)scrollTo
{
    
    if ([self isLoading]) {
        return CGRectNull;
    }
    
    NSString *payload = [NSString stringWithFormat:@"var el = document.querySelector(\"%@\"); %@ var rect = window._$getElementRect(el); JSON.stringify(rect);", [elementSelector ob_javaScriptEscapedString], (scrollTo ? @"window._$scrollToElement(el);" : @"")];
    NSArray <NSNumber *> *result = [self ob_evaluateJavaScript:payload shouldParseJSON:YES];
    if (![result isKindOfClass:[NSArray class]] || result.count != 4) {
        return CGRectNull;
    }
    
#if defined(__LP64__) && __LP64__
    return CGRectMake([result[0] doubleValue], [result[1] doubleValue], [result[2] doubleValue], [result[3] doubleValue]);
#else
    return CGRectMake([result[0] floatValue], [result[1] floatValue], [result[2] floatValue], [result[3] floatValue]);
#endif
    
}


#pragma mark - Private


/**
 * Evaluate JavaScript in UIWebView synchronously.
 *
 * @param payload The script to be evaluated.
 * @param parse Since -stringByEvaluatingJavaScriptFromString: does not support types of return value other than string, you may pass YES to this argument to parse its return value from JSON format.
 * @returns Returned or parsed representatin of JavaScript object in Objective-C.
 */
- (nullable id)ob_evaluateJavaScript:(NSString *)payload shouldParseJSON:(BOOL)parse
{
    
    NSString *evaluatedString = [self stringByEvaluatingJavaScriptFromString:payload];
    if (parse) {
        NSData *evaluatedData = [evaluatedString dataUsingEncoding:NSUTF8StringEncoding];
        if (!evaluatedData) {
            return nil;
        }
        return [NSJSONSerialization JSONObjectWithData:evaluatedData options:0 error:nil];
    }
    return evaluatedString;
    
}


@end

#endif  // ENABLE_UIWEBVIEW

