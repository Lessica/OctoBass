//
//  UIImage+Screenshotr.h
//  OctoBass
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Screenshotr)

- (void)ob_saveToCameraRoll;
- (BOOL)ob_writeToFile:(NSString *)path;

@end

NS_ASSUME_NONNULL_END

