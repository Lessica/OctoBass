//
//  OBClassHierarchyDetector.m
//  OctoBass
//

#import "OBClassHierarchyDetector.h"
#import "objc/runtime.h"


@implementation OBClassHierarchyDetector {
    
    /// Used internally to store the list of classes in the runtime.
    Class *classes;
    
    /// Used internally to store the number of classes in the runtime (array length).
    int numClasses;
    
    /// Allowed classes bundles.
    NSArray <NSBundle *> *allowedBundles;
    
}


#pragma mark - Initializers


- (instancetype)initWithBundles:(NSArray <NSBundle *> *)bundles
{
    NSAssert(bundles.count != 0, @"you must provide at least one bundle");
    
    self = [super init];
    if (self) {
        
        // Fetch the list of classes from the runtime.
        // @see http://www.cocoawithlove.com/2010/01/getting-subclasses-of-objective-c-class.html
        numClasses = objc_getClassList(NULL, 0);
        classes = NULL;
        if (numClasses > 0) {
            classes = (Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
        }
        allowedBundles = bundles;
        
    }
    return self;
}


- (void)dealloc {
    // Free the memory allocated previously.
    free(classes); classes = NULL;
    numClasses = 0;
    allowedBundles = nil;
}


#pragma mark - Public methods


- (void)printHierarchyOfClass:(Class)class
               formatterBlock:(NSString * (^)(OBClassRepresentation *))formatterBlock
            indentationString:(NSString *)indentationString
{
    // Create a representation of the specified class (and subclasses, recursively).
    OBClassRepresentation *repr = [self representationOfClass:class];

    // Recursively print the representation of the specified class and all of
    // it descendants.
    [self recursivelyPrintOBClassRepresentation:repr
                                 formatterBlock:formatterBlock
                              indentationString:indentationString
                               indentationLevel:0];
}


- (nullable OBClassRepresentation *)representationOfClass:(Class)class
{
    OBClassRepresentation *repr = [[OBClassRepresentation alloc] init];

    repr.name = NSStringFromClass(class);
    repr.isBundled = YES;

    // Add the representation of the subclasses
    NSMutableArray *subclassesArray = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++) {
        Class superClass = class_getSuperclass(classes[i]);
        if (superClass == class) {
            OBClassRepresentation *childClsRepr = [self representationOfClass:classes[i]];
            if (childClsRepr) {
                [subclassesArray addObject:childClsRepr];
            }
        }
    }
    
    if (![allowedBundles containsObject:[NSBundle bundleForClass:class]]) {
        if (subclassesArray.count == 0) {
            return nil;
        }
        else {
            repr.isBundled = NO;
        }
    }
    
    repr.subclassesRepresentations = subclassesArray;

    return repr;
}


#pragma mark - Private methods


/**
 * Recursively prints a OBClassRepresentation object and all of its nested 
 * subclassesRepresentations.
 *
 * @param repr the representation of the class whose hierarchy
 *        needs to be printed.
 *
 * @param formatterBlock a block used to create a descriptive string from a
 *        OBClassRepresentation.
 *
 * @param indentationString a string used to indent the description of a class
 *        depending on its depth level in the hierarchy.
 *
 * @param indentationLevel the level of indentation that should be used when
 *        printing the current class.
 */
- (void)recursivelyPrintOBClassRepresentation:(OBClassRepresentation *)repr
                               formatterBlock:(NSString * (^)(OBClassRepresentation *))formatterBlock
                            indentationString:(NSString *)indentationString
                             indentationLevel:(int)indentationLevel
{
    NSString *currRepr = @"";

    // Add the indentation
    for (int i = 0; i < indentationLevel; i++) {
        currRepr = [indentationString stringByAppendingString:currRepr];
    }

    // Add the current class representation
    currRepr = [currRepr stringByAppendingString:formatterBlock(repr)];

    // Log it to the console
    printf("%s\n", currRepr.UTF8String);

    // Cycle through the nested subclasses
    for (OBClassRepresentation *subRepr in repr.subclassesRepresentations) {
        [self recursivelyPrintOBClassRepresentation:subRepr
                                     formatterBlock:formatterBlock
                                  indentationString:indentationString
                                   indentationLevel:indentationLevel + 1];
    }
}


@end


#pragma mark - OBClassRepresentation


/// No implementation needed, since this is just a DTO
@implementation OBClassRepresentation

@end

