//
//  OBViewInjector.m
//  OctoBass
//

#import "OBViewInjector.h"
#import <UIKit/UIKit.h>

#import "MyCHHook.h"
#import "OBClassHierarchyDetector.h"


@implementation OBViewInjector


#pragma mark - Global Variables

static NSMutableSet <NSString *> *_$clsNames = nil;


#pragma mark - UIView Methods


/**
 * The same as -[UIView didMoveToSuperview].
 * Creates and adds outline views to views we concerned.
 */
static void (*orig_UIView_didMoveToSuperview)(UIView *, SEL);
static void repl_UIView_didMoveToSuperview(UIView *self, SEL _cmd)
{
    
    NSString *clsName = NSStringFromClass([self class]);
    if ([_$clsNames containsObject:clsName]) {
        
        if (self.superview != nil) {
            
            // moved to superview
            NSString *supClsName = NSStringFromClass([self.superview class]);
            MyLog(@"%@ moved to %@", clsName, supClsName);
            
        } else {
            
            // removed from superview
            MyLog(@"%@ removed from its superview", clsName);
            
        }
        
    }
    
    orig_UIView_didMoveToSuperview(self, _cmd);
}


static void (*orig_UIApplication_sendEvent_)(UIApplication *, SEL, UIEvent *);
static void repl_UIApplication_sendEvent_(UIApplication *self, SEL _cmd, UIEvent *event)
{
    MyLog(@"%@", event);
    orig_UIApplication_sendEvent_(self, _cmd, event);
}


#pragma mark - Injection Initializers


- (instancetype)init {
    self = [super init];
    if (self) {
        
        // Returns an array of all of the application’s bundles that represent frameworks.
        NSMutableArray <NSBundle *> *allowedBundles = [NSMutableArray arrayWithObject:[NSBundle mainBundle]];
        [allowedBundles addObjectsFromArray:[NSBundle allFrameworks]];
        [allowedBundles filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSBundle *evaluatedBundle, NSDictionary *bindings) {
            NSString *bundlePath = [evaluatedBundle bundlePath];
            return [bundlePath hasPrefix:@"/var/"] || [bundlePath hasPrefix:@"/private/var/"];
        }]];
        
        // New class hierarchy detector, which caches all objc classes.
        OBClassHierarchyDetector *clsDetector = [[OBClassHierarchyDetector alloc] initWithBundles:allowedBundles];
        
        // Caches all UIView classes recursively.
        _$clsNames = [NSMutableSet set];
        [self prepareOBClassRepresentation:[clsDetector representationOfClass:[UIView class]]];
        
        // Hook view methods.
        MyHookMessage([UIView class], @selector(didMoveToSuperview), (IMP)repl_UIView_didMoveToSuperview, (IMP *)&orig_UIView_didMoveToSuperview);
        MyHookMessage([UIApplication class], @selector(sendEvent:), (IMP)repl_UIApplication_sendEvent_, (IMP *)&orig_UIApplication_sendEvent_);
        
    }
    return self;
}


#pragma mark - Filter Caching


/**
 * Prepares UIVIew class names for view filtering in hooked view methods.
 * @param clsRepr the class representation to be prepared.
 */
- (void)prepareOBClassRepresentation:(OBClassRepresentation *)clsRepr {
    if (clsRepr.isIncluded) {
        [_$clsNames addObject:clsRepr.name];
    }
    for (OBClassRepresentation *subRepr in clsRepr.subclassesRepresentations) {
        [self prepareOBClassRepresentation:subRepr];
    }
}


@end
