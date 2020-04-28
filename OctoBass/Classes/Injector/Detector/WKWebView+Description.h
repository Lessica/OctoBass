//
//  WKWebView+Description.h
//  OctoBass
//

#import <WebKit/WebKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (Description)


/**
 * Returns a string that describes the contents of the receiver.
 *
 * @returns A string that describes the contents of the receiver.
 */
- (NSString *)ob_description;


@end

NS_ASSUME_NONNULL_END

