//
//  OBViewInjector.m
//  OctoBass
//

#import "OBViewInjector.h"
#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <WebKit/WebKit.h>

#import "MyCHHook.h"
#import "OBClassHierarchyDetector.h"
#import "OBTouchRocket.h"

#import "UIView+Hierarchy.h"
#import "UIWindow+Hierarchy.h"
#import "UIWebView+Description.h"
#import "WKWebView+Description.h"


@implementation OBViewInjector


#pragma mark - Global Variables

static NSMutableSet <NSString *> *_$clsNames = nil;


#pragma mark - UIView Methods


/**
 * - [UIView didMoveToSuperview]
 */
static void (*orig_UIView_didMoveToSuperview)(UIView *, SEL);
static void repl_UIView_didMoveToSuperview(UIView *self, SEL _cmd)
{
    
    // self class name
    NSString *clsName = NSStringFromClass([self class]);
    
    // self.superview class name
    NSString *supClsName = nil;
    if (self.superview != nil) {
        supClsName = NSStringFromClass([self.superview class]);
    }
    
    // SDK views only
    if ((clsName != nil && [_$clsNames containsObject:clsName]) ||
        (supClsName != nil && [_$clsNames containsObject:supClsName])
        )
    {
        
        // added to superview
        if (supClsName != nil) {
            
            MyLog(@"%@ moved to %@", clsName, supClsName);
            
            // skip empty views
            if (!CGRectIsEmpty(self.bounds)) {
                
                CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
                CGPoint pointInWindow = [self convertPoint:center toView:nil];
                
#if DEBUG
                [OBViewInjector printViewHierarchyAtPoint:pointInWindow];
#endif
                
                
                
            }
            
        }
        
        // removed from superview
        else {
            
            MyLog(@"%@ removed from its superview", clsName);
            
        }
        
    }
    
    orig_UIView_didMoveToSuperview(self, _cmd);
    
}


#if DEBUG
/**
 * - [UIApplication sendEvent:]
 */
static void (*orig_UIApplication_sendEvent_)(UIApplication *, SEL, UIEvent *);
static void repl_UIApplication_sendEvent_(UIApplication *self, SEL _cmd, UIEvent *event)
{
    
    // Only detects single touch object.
    if (event.allTouches.count == 1) {
        
        // Get the only touch object.
        UITouch *touchObj = [event.allTouches anyObject];
        
        // tap: began -> ended
        if (touchObj.phase == UITouchPhaseEnded) {
            
            // Get location in its window coordinate.
            CGPoint locInWindow = [touchObj locationInView:nil];
            MyLog(@"tapped at point (%d, %d)", (int)floor(locInWindow.x), (int)floor(locInWindow.y));
            
        }
        
    }
    
    orig_UIApplication_sendEvent_(self, _cmd, event);
    
}
#endif


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
#if DEBUG
        MyHookMessage([UIApplication class], @selector(sendEvent:), (IMP)repl_UIApplication_sendEvent_, (IMP *)&orig_UIApplication_sendEvent_);
#endif
        
    }
    return self;
}


#pragma mark - Filter Caching


/**
 * Prepares UIVIew class names for view filtering in hooked view methods.
 * @param clsRepr the class representation to be prepared.
 */
- (void)prepareOBClassRepresentation:(OBClassRepresentation *)clsRepr {
    
    if (clsRepr.isBundled) {
        [_$clsNames addObject:clsRepr.name];
    }
    
    for (OBClassRepresentation *subRepr in clsRepr.subclassesRepresentations) {
        [self prepareOBClassRepresentation:subRepr];
    }
    
}


#pragma mark - Private


+ (void)printViewHierarchyAtPoint:(CGPoint)point {
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    UIView *topView = [keyWindow ob_viewAtPoint:point];
    
    NSMutableString *hierarchyLogs = [NSMutableString stringWithString:@"\n[\n"];
    
    for (UIView *view in [topView ob_superviews]) {
        
        NSString *log = nil;
        if ([view respondsToSelector:@selector(ob_description)]) {
            log = [view performSelector:@selector(ob_description)];
        } else {
            log = [view description];
        }
        
        if (log) {
            [hierarchyLogs appendFormat:@"    \"%@\",\n", log];
        }
        
    }
    
    [hierarchyLogs appendString:@"]"];
    MyLog(@"%@", hierarchyLogs);
    
}


@end

