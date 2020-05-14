//
//  WKWebView+Description.m
//  OctoBass
//

#import "WKWebView+Description.h"
#import "UIView+Description.h"
#import "WKUserContentController+Inspector.h"

#import "NSString+Hashes.h"


@implementation WKWebView (Description)


- (NSString *)ob_description {
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d); url = %@; media = %@; hash = %@>",
            NSStringFromClass([self class]),
            self,
            (int)self.bounds.origin.x,
            (int)self.bounds.origin.y,
            (int)self.bounds.size.width,
            (int)self.bounds.size.height,
            self.URL,
            [self.configuration.userContentController ob_lastMediaStatusDictionary][@"src"],
            [self ob_inspectorHash]
            ];
}

- (NSString *)ob_shortDescription {
    return [NSString stringWithFormat:@"<%@; hash = %@>", NSStringFromClass([self class]), [self ob_inspectorHash]];
}


#pragma mark - Private

- (nullable NSString *)ob_inspectorReportedHash {
    return [self.configuration.userContentController ob_inspectorReportedHash];
}

- (nullable NSString *)ob_inspectorHash {
    return [[self ob_inspectorReportedHash] ob_sha1];
}


@end

