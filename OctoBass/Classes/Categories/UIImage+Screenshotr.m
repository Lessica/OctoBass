//
//  UIImage+Screenshotr.m
//  OctoBass
//

#import "UIImage+Screenshotr.h"


@implementation UIImage (Screenshotr)

- (void)ob_saveToCameraRoll {
    UIImageWriteToSavedPhotosAlbum([UIImage imageWithData:UIImagePNGRepresentation(self)], nil, nil, NULL);
}

- (BOOL)ob_writeToFile:(NSString *)path {
    return [UIImagePNGRepresentation(self) writeToFile:path atomically:YES];
}

@end

