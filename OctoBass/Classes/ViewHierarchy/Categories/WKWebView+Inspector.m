//
//  WKWebView+Inspector.m
//  OctoBass
//

#import "WKWebView+Inspector.h"


@interface NSString (JavaScriptEscape)
- (NSString *)ob_javaScriptEscapedString;
@end

@implementation NSString (JavaScriptEscape)
- (NSString *)ob_javaScriptEscapedString {
    // valid JSON object need to be an array or dictionary
    NSArray *arrayForEncoding = @[self];
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSString *escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
    return escapedString;
}
@end


@implementation WKWebView (Inspector)


- (nullable NSString *)ob_getElementSelectorByViewPortPoint:(CGPoint)point shouldHighlight:(BOOL)highlight
{
    
    NSString *payload = [NSString stringWithFormat:@"var el = document.elementFromPoint(%f, %f); var sel = window._$getElementSelector(el); %@ sel;", point.x, point.y, (highlight ? @"window._$highlightElement(el);" : @"")];
    
    NSString *result = [self ob_evaluateJavaScript:payload];
    if (![result isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    return result;
    
}


- (CGRect)ob_getViewPortRectByElementSelector:(NSString *)elementSelector shouldScrollTo:(BOOL)scrollTo
{
    
    NSString *payload = [NSString stringWithFormat:@"var el = document.querySelector(\"%@\"); %@ var rect = window._$getElementRect(el); rect;", [elementSelector ob_javaScriptEscapedString], (scrollTo ? @"window._$scrollToElement(el);" : @"")];
    NSArray <NSNumber *> *result = [self ob_evaluateJavaScript:payload];
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


- (id)ob_evaluateJavaScript:(NSString *)payload
{
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    __block id result = nil;
    [self evaluateJavaScript:payload completionHandler:^(id _Nullable obj, NSError * _Nullable error) {
        result = obj;
        dispatch_semaphore_signal(sema);
    }];
    
    if (![NSThread isMainThread]) {
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    } else {
        while (dispatch_semaphore_wait(sema, DISPATCH_TIME_NOW)) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0]];
        }
    }
    
    return [result copy];
    
}


@end

