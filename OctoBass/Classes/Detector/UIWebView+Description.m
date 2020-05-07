//
//  UIWebView+Description.m
//  OctoBass
//

#import "UIWebView+Description.h"


@implementation UIWebView (Description)


- (NSString *)ob_description {
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d); url = %@>", NSStringFromClass([self class]), self, (int)self.bounds.origin.x, (int)self.bounds.origin.y, (int)self.bounds.size.width, (int)self.bounds.size.height, self.request.URL];
}


@end

