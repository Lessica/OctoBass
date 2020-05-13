//
//  NSURL+QueryDictionary.h
//  OctoBass
//

#import <Foundation/Foundation.h>

@interface NSURL (OB_URLQuery)

/**
 *  @return URL's query component as keys/values
 *  Returns nil for an empty query
 */
- (NSDictionary *)ob_queryDictionary;

/**
 *  @return URL with keys values appending to query string
 *  @param queryDictionary Query keys/values
 *  @param sortedKeys Sorted the keys alphabetically?
 *  @warning If keys overlap in receiver and query dictionary,
 *  behaviour is undefined.
 */
- (NSURL *)ob_URLByAppendingQueryDictionary:(NSDictionary *)queryDictionary
                            withSortedKeys:(BOOL)sortedKeys;

/** As above, but `sortedKeys=NO` */
- (NSURL *)ob_URLByAppendingQueryDictionary:(NSDictionary *)queryDictionary;

/**
 *  @return Copy of URL with its query component replaced with
 *  the specified dictionary.
 *  @param queryDictionary A new query dictionary
 *  @param sortedKeys      Whether or not to sort the query keys
 */
- (NSURL *)ob_URLByReplacingQueryWithDictionary:(NSDictionary *)queryDictionary
                                withSortedKeys:(BOOL) sortedKeys;

/** As above, but `sortedKeys=NO` */
- (NSURL *)ob_URLByReplacingQueryWithDictionary:(NSDictionary *)queryDictionary;

/** @return Receiver with query component completely removed */
- (NSURL *)ob_URLByRemovingQuery;

@end

#pragma mark -

@interface NSString (OB_URLQuery)

/**
 *  @return If the receiver is a valid URL query component, returns
 *  components as key/value pairs. If couldn't split into *any* pairs,
 *  returns nil.
 */
- (NSDictionary *)ob_URLQueryDictionary;

@end

#pragma mark -

@interface NSDictionary (OB_URLQuery)

/**
 *  @return URL query string component created from the keys and values in
 *  the dictionary. Returns nil for an empty dictionary.
 *  @param sortedKeys Sorted the keys alphabetically?
 *  @see cavetas from the main `NSURL` category as well.
 */
- (NSString *)ob_URLQueryStringWithSortedKeys:(BOOL)sortedKeys;

/** As above, but `sortedKeys=NO` */
- (NSString *)ob_URLQueryString;

@end
