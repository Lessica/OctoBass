//
//  UIWebView+Description.m
//  OctoBass
//

#import "UIWebView+Description.h"
#import "UIView+Description.h"
#import "UIWebView+Inspector.h"

#import "NSString+Hashes.h"


@implementation UIWebView (Description)


- (NSString *)ob_description {
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d); url = %@>", NSStringFromClass([self class]), self, (int)self.bounds.origin.x, (int)self.bounds.origin.y, (int)self.bounds.size.width, (int)self.bounds.size.height, self.request.URL];
}

- (NSString *)ob_shortDescription {
    return [NSString stringWithFormat:@"<%@; hash = %@>", NSStringFromClass([self class]), [self ob_inspectorHash]];
}


#pragma mark - Private

- (NSString *)ob_inspectorReportedHash {
    return [self ob_inspectorReportedHash];
}

- (NSString *)ob_inspectorHash {
    return [[self ob_inspectorReportedHash] ob_sha1];
}


@end
