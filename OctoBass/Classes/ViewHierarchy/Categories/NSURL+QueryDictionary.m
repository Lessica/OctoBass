//
//  NSURL+QueryDictionary.m
//  OctoBass
//

#import "NSURL+QueryDictionary.h"

static NSString *const ob_URLReservedChars  = @"￼=,!$&'()*+;@?\r\n\"<>#\t :/";
static NSString *const kQuerySeparator      = @"&";
static NSString *const kQueryDivider        = @"=";
static NSString *const kQueryBegin          = @"?";
static NSString *const kFragmentBegin       = @"#";

@implementation NSURL (OB_URLQuery)

- (NSDictionary *)ob_queryDictionary {
    return self.query.ob_URLQueryDictionary;
}

- (NSURL *)ob_URLByAppendingQueryDictionary:(NSDictionary *)queryDictionary {
    return [self ob_URLByAppendingQueryDictionary:queryDictionary withSortedKeys:NO];
}

- (NSURL *)ob_URLByAppendingQueryDictionary:(NSDictionary *)queryDictionary
                             withSortedKeys:(BOOL)sortedKeys
{
    NSMutableArray *queries = [self.query length] > 0 ? @[self.query].mutableCopy : @[].mutableCopy;
    NSString *dictionaryQuery = [queryDictionary ob_URLQueryStringWithSortedKeys:sortedKeys];
    if (dictionaryQuery) {
        [queries addObject:dictionaryQuery];
    }
    NSString *newQuery = [queries componentsJoinedByString:kQuerySeparator];
    
    if (newQuery.length) {
        NSArray *queryComponents = [self.absoluteString componentsSeparatedByString:kQueryBegin];
        if (queryComponents.count) {
            return [NSURL URLWithString:
                    [NSString stringWithFormat:@"%@%@%@%@%@",
                     queryComponents[0],                      // existing url
                     kQueryBegin,
                     newQuery,
                     self.fragment.length ? kFragmentBegin : @"",
                     self.fragment.length ? self.fragment : @""]];
        }
    }
    return self;
}

- (NSURL *)ob_URLByRemovingQuery {
    NSArray *queryComponents = [self.absoluteString componentsSeparatedByString:kQueryBegin];
    if (queryComponents.count) {
        return [NSURL URLWithString:queryComponents.firstObject];
    }
    return self;
}

- (NSURL *)ob_URLByReplacingQueryWithDictionary:(NSDictionary *)queryDictionary {
    return [self ob_URLByReplacingQueryWithDictionary:queryDictionary withSortedKeys:NO];
}

- (NSURL *)ob_URLByReplacingQueryWithDictionary:(NSDictionary *)queryDictionary
                                 withSortedKeys:(BOOL)sortedKeys
{
    NSURL *stripped = [self ob_URLByRemovingQuery];
    return [stripped ob_URLByAppendingQueryDictionary:queryDictionary withSortedKeys:sortedKeys];
}

@end

#pragma mark -

@implementation NSString (URLQuery)

- (NSDictionary *)ob_URLQueryDictionary {
    NSMutableDictionary *mute = @{}.mutableCopy;
    for (NSString *query in [self componentsSeparatedByString:kQuerySeparator]) {
        NSArray *components = [query componentsSeparatedByString:kQueryDivider];
        if (components.count == 0) {
            continue;
        }
        NSString *key = [components[0] stringByRemovingPercentEncoding];
        id value = nil;
        if (components.count == 1) {
            // key with no value
            value = [NSNull null];
        }
        if (components.count == 2) {
            value = [components[1] stringByRemovingPercentEncoding];
            // cover case where there is a separator, but no actual value
            value = [value length] ? value : [NSNull null];
        }
        if (components.count > 2) {
            // invalid - ignore this pair. is this best, though?
            continue;
        }
        mute[key] = value ?: [NSNull null];
    }
    return mute.count ? mute.copy : nil;
}

- (NSString *)ob_stringByPercentageEncodingWithReservedCharacters {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:
            [NSCharacterSet URLQueryAllowedCharacterSet]];
}

@end

#pragma mark -

@implementation NSDictionary (URLQuery)

- (NSString *)ob_URLQueryString {
    return [self ob_URLQueryStringWithSortedKeys:NO];
}

- (NSString *)ob_URLQueryStringWithSortedKeys:(BOOL)sortedKeys {
    NSMutableString *queryString = @"".mutableCopy;
    NSArray *keys = sortedKeys ? [self.allKeys sortedArrayUsingSelector:@selector(compare:)] : self.allKeys;
    for (NSString *key in keys) {
        id rawValue = self[key];
        NSString *value = nil;
        // beware of empty or null
        if (!(rawValue == [NSNull null] || ![rawValue description].length)) {
            value = [self[key] description];
        }
        [queryString appendFormat:@"%@%@%@%@",
         queryString.length ? kQuerySeparator : @"",    // appending?
         key,
         value ? kQueryDivider : @"",
         value ? value : @""];
    }
    return queryString.length ? [queryString ob_stringByPercentageEncodingWithReservedCharacters] : nil;
}

@end
