//
//  UIWebView+Description.m
//  OctoBass
//

#if ENABLE_UIWEBVIEW

#import "UIWebView+Description.h"
#import "UIView+Description.h"
#import "UIWebView+Inspector.h"

#import "NSString+Hashes.h"


@implementation UIWebView (Description)


- (NSString *)ob_description {
    NSString *mediaSrc = [self ob_lastMediaStatusDictionary][@"src"];
    return [NSString stringWithFormat:@"<%@: 0x%p; frame = (%d %d; %d %d); url = %@;%@ hash = %@>",
            NSStringFromClass([self class]),
            self,
            (int)self.bounds.origin.x,
            (int)self.bounds.origin.y,
            (int)self.bounds.size.width,
            (int)self.bounds.size.height,
            self.request.URL,
            mediaSrc ? [NSString stringWithFormat:@" media = %@;", mediaSrc] : @"",
            [self ob_inspectorHash]
            ];
}


#pragma mark - Private

- (NSString *)ob_inspectorHash {
    return [[self ob_inspectorReportedHash] ob_sha1];
}


@end

#endif  // ENABLE_UIWEBVIEW

