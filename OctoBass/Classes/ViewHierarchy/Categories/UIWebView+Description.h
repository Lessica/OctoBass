//
//  UIWebView+Description.h
//  OctoBass
//

#if ENABLE_UIWEBVIEW

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface UIWebView (Description)


/**
 * Returns a string that describes the contents of the receiver.
 *
 * @returns A string that describes the contents of the receiver.
 */
- (NSString *)ob_description;


@end

NS_ASSUME_NONNULL_END

#endif
