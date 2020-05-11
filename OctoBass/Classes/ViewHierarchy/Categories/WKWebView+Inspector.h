//
//  WKWebView+Inspector.h
//  OctoBass
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (Inspector)


/**
 * Get the DOM selector of an element which locates at specified point inside view-port.
 *
 * @param point A location where the element locates at.
 * @returns The DOM selector of the located element.
 */
- (nullable NSString *)ob_getElementSelectorByViewPortPoint:(CGPoint)point shouldHighlight:(BOOL)highlight;


/**
 * Get the view-port rect of an element by its DOM selector.
 *
 * @param elementSelector The DOM selector of the target element.
 * @returns The view-port rect of the target element.
 */
- (CGRect)ob_getViewPortRectByElementSelector:(NSString *)elementSelector shouldScrollTo:(BOOL)scrollTo;


@end

NS_ASSUME_NONNULL_END
