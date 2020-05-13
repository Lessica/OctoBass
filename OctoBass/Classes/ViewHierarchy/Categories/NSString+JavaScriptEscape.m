//
//  NSString+JavaScriptEscape.m
//  OctoBass
//

#import "NSString+JavaScriptEscape.h"


@implementation NSString (JavaScriptEscape)

- (NSString *)ob_javaScriptEscapedString {
    // valid JSON object need to be an array or dictionary
    NSArray *arrayForEncoding = @[self];
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:arrayForEncoding options:0 error:nil] encoding:NSUTF8StringEncoding];
    NSString *escapedString = [jsonString substringWithRange:NSMakeRange(2, jsonString.length - 4)];
    return escapedString;
}

@end

