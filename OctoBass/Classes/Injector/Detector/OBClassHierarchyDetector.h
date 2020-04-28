//
//  OBClassHierarchyDetector.h
//  OctoBass
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@class OBClassRepresentation; // See below


/**
 * Helper that provides functionality to print the hierarchy of a class.
 */
@interface OBClassHierarchyDetector : NSObject


- (instancetype)init NS_UNAVAILABLE;


/**
 * Initialize a class hierarchy detector with allowed bundles. Classes are restricted to provided bundles.
 *
 * @param bundles allowed bundles.
 */
- (instancetype)initWithBundles:(NSArray <NSBundle *> *)bundles;


/**
 * Prints the hierarchy of the specified class.
 *
 * @param class the class whose hierarchy needs to be printed.
 *
 * @param formatterBlock a block used to create a descriptive string from a
 *        OBClassRepresentation.
 *
 * @param indentationString a string used to indent the description of a class
 *        depending on its depth level in the hierarchy.
 */
- (void)printHierarchyOfClass:(Class)class
               formatterBlock:(NSString * (^)(OBClassRepresentation *clsRepr))formatterBlock
            indentationString:(NSString *)indentationString;


/**
 * Returns a OBClassRepresentation object created using the specified class.
 *
 * @param class the class whose hierarchy needs to be fetched.
*/
- (nullable OBClassRepresentation *)representationOfClass:(Class)class;


@end


/**
 * Object used to represent a class in the hierarchy. Contains a name and an
 * array of subclasses.
 *
 * It's a inner class used as a DTO.
 */
@interface OBClassRepresentation : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) BOOL isBundled;
@property (nonatomic, strong) NSArray <OBClassRepresentation *> *subclassesRepresentations;

@end

NS_ASSUME_NONNULL_END

