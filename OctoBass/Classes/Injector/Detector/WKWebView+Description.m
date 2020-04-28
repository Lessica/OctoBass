//
//  WKWebView+Description.m
//  OctoBass
//

#import "WKWebView+Description.h"


@implementation WKWebView (Description)


- (NSString *)ob_description {
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d); url = %@>", NSStringFromClass([self class]), self, (int)self.bounds.origin.x, (int)self.bounds.origin.y, (int)self.bounds.size.width, (int)self.bounds.size.height, self.URL];
}


@end

