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
    NSString *mediaSrc = [self.configuration.userContentController ob_lastMediaStatusDictionary][@"src"];
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d); url = %@;%@ hash = %@>",
            NSStringFromClass([self class]),
            self,
            (int)self.bounds.origin.x,
            (int)self.bounds.origin.y,
            (int)self.bounds.size.width,
            (int)self.bounds.size.height,
            self.URL,
            mediaSrc ? [NSString stringWithFormat:@" media = %@;", mediaSrc] : @"",
            [self ob_inspectorHash]
            ];
}


#pragma mark - Private

- (nullable NSString *)ob_inspectorHash {
    return [[self.configuration.userContentController ob_inspectorReportedHash] ob_sha1];
}


@end

