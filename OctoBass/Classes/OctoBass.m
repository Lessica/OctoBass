//
//  OctoBass.m
//  OctoBass
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <WebKit/WebKit.h>
#import <pthread.h>

#import "MyCHHook.h"
#import "OBClassHierarchyDetector.h"
#import "OBTouchRocket.h"

#import "UIView+Hierarchy.h"
#import "UIWindow+Hierarchy.h"
#import "UIView+Description.h"
#import "UIWebView+Description.h"
#import "WKWebView+Description.h"
#import "NSString+Hashes.h"

#import "OBWKWebViewMsgProxy.h"


#pragma mark - Global Variables

static NSMutableSet <NSString *> *_$clsNames = nil;
static NSMutableDictionary <NSString *, NSDictionary *> *_$viewHashesAndActions = nil;


#pragma mark - WKWebView Methods


static WKWebView *(*orig_WKWebView_initWithFrame_configuration_)(WKWebView *, SEL, CGRect, WKWebViewConfiguration *);
static WKWebView *repl_WKWebView_initWithFrame_configuration_(WKWebView *self, SEL _cmd, CGRect frame, WKWebViewConfiguration *configuration)
{
    
    static NSString *inspectorJS = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // FIXME: Load inspector js securely
        NSBundle *resBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"OctoBass" ofType:@"bundle"]];
        NSString *jsPath = [resBundle pathForResource:@"webinspectord" ofType:@"js"];
        NSData *jsData = [[NSData alloc] initWithContentsOfFile:jsPath];
        inspectorJS = [[NSString alloc] initWithData:jsData encoding:NSUTF8StringEncoding];
        
    });
    
    if (!inspectorJS) {
        return orig_WKWebView_initWithFrame_configuration_(self, _cmd, frame, configuration);
    }
    
    
    // Get its user content controller.
    WKUserContentController *userContentController = configuration.userContentController;
    
    
    // Add inspector message handlers.
    static NSString *inspectorMsgHandlerName = @"_$webinspectord_report";
    [userContentController removeScriptMessageHandlerForName:inspectorMsgHandlerName];
    [userContentController addScriptMessageHandler:[OBWKWebViewMsgProxy new] name:inspectorMsgHandlerName];
    
    
    // Check if it's already injected.
    BOOL alreadyInjected = NO;
    for (WKUserScript *script in userContentController.userScripts) {
        if ([script.source isEqualToString:inspectorJS]) {
            alreadyInjected = YES;
            break;
        }
    }
    
    
    // Inject if needed.
    if (!alreadyInjected) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:inspectorJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:userScript];
    }
    
    
    // Call original initializer.
    return orig_WKWebView_initWithFrame_configuration_(self, _cmd, frame, configuration);
    
}


#pragma mark - Event Logging


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
            MyLog(@"TAPPED coordinate = (%d, %d)", (int)locInWindow.x, (int)locInWindow.y);
            
        }
        
    }
    
    orig_UIApplication_sendEvent_(self, _cmd, event);
    
}
#endif


#pragma mark - Filter Caching


/**
 * Prepares UIVIew class names for view filtering in hooked view methods.
 * @param clsRepr the class representation to be prepared.
 */
static void prepareOBClassRepresentation(OBClassRepresentation *clsRepr) {
    
    if (clsRepr.isBundled) {
        [_$clsNames addObject:clsRepr.name];
    }
    
    for (OBClassRepresentation *subRepr in clsRepr.subclassesRepresentations) {
        prepareOBClassRepresentation(subRepr);
    }
    
}


#pragma mark - View Processing


static pthread_mutex_t _$serialActionLock = PTHREAD_MUTEX_INITIALIZER;
static dispatch_queue_t _$serialActionQueue;

static UIWindow *applicationTopMostWindow         (void);
static BOOL      serialProcessViewAtPoint         (CGPoint point);
static BOOL      serialProcessView                (UIView *view);
static NSString *computeHashOfViewHierarchyAtPoint(CGPoint point, UIWindow *refWindow);
static NSString *computeHashOfViewHierarchy       (UIView *topView);


BOOL serialProcessViewAtPoint(CGPoint point) {
    UIWindow *topWindow = applicationTopMostWindow();
    if (!topWindow) { return NO; }
    return serialProcessView([topWindow ob_viewAtPoint:point]);
}


BOOL serialProcessView(UIView *view) {
    
    assert([NSThread isMainThread]);
    assert(view != nil && ![view isHidden]);
    
    
    // Compute hash for view hierarchy at center point
    UIWindow *refWindow = view.window;
    assert(refWindow != nil && refWindow.isHidden == NO);
    
    
    CGPoint center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    CGPoint pointInWindow = [view convertPoint:center toView:nil];
    NSString *hashAtPoint = computeHashOfViewHierarchy(view);
    
    
    // Fetch action for hash
    NSDictionary *actionForHash = [_$viewHashesAndActions objectForKey:hashAtPoint];
    
    
    // Filter: No matching hash
    if (!actionForHash) {  /* ![actionForHash isKindOfClass:[NSDictionary class]] */
        
        MyLog(@"skipped: no matching hash %@", hashAtPoint);
        return NO;
        
    }
    
    
    // Action phases
    NSArray <NSDictionary *> *actionPhases = actionForHash[@"phases"];
    assert([actionPhases isKindOfClass:[NSArray class]]);
    
    
    // Filter: Serial action queue is busy
    if (pthread_mutex_trylock(&_$serialActionLock) != 0) {
        
        MyLog(@"skipped: serial action queue is busy");
        return NO;
        
    }
    
    
    // Begin task
    MyLog(@"processing: hash %@", hashAtPoint);
    
    
    // Enumate action phases in a global queue
    dispatch_async(_$serialActionQueue, ^{
        
        int phaseIndex = 0;
        for (NSDictionary *actionPhase in actionPhases) {
            
            
            NSString *actionType = actionPhase[@"type"] ?: @"TAP";
            NSTimeInterval actionDelay = [actionPhase[@"delay"] doubleValue];
            
            
            // Set minimum/maximum delay
            if (actionDelay < 0.5) {
                actionDelay = 0.5;
            }
            else if (actionDelay > 60.0) {
                actionDelay = 60.0;
            }
            
            
            // Delay
            [NSThread sleepForTimeInterval:actionDelay];
            
            
            // Action TAP
            if ([actionType isEqualToString:@"TAP"]) {
                
                
                // a1. Default tap coordinate
                CGPoint tapCoord = pointInWindow;
                NSString *phaseCoord = actionPhase[@"coordinate"];
                
                
                // a2. Use special tap coordinate
                if ([phaseCoord hasPrefix:@"!"]) {
                    
                    if ([phaseCoord isEqualToString:@"!CENTER"]) {
                        // default behavior
                    }
                    
                }
                
                
                // a3. Use scanned tap coordinate
                else if ([phaseCoord length] > 0) {
                    
                    NSScanner *coordScanner = [NSScanner scannerWithString:phaseCoord];
                    coordScanner.charactersToBeSkipped = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
                    
                    int coordX; BOOL coordXScanned = [coordScanner scanInt:&coordX];
                    int coordY; BOOL coordYScanned = [coordScanner scanInt:&coordY];
                    assert (coordXScanned && coordYScanned);
                    
                    tapCoord.x = coordX * 1.0;
                    tapCoord.y = coordY * 1.0;
                    
                }
                
                
                // b1. Default hash validation
                NSString *hashValidation = actionPhase[@"hashValidation"];
                
                
                // b2. Use special hash validation
                if ([hashValidation hasPrefix:@"!"]) {
                    
                    if ([hashValidation isEqualToString:@"!SKIP"]) {
                        // default behavior
                        hashValidation = nil;  // !important
                    }
                    
                }
                
                
                // b3. use original hash as its validation
                else if (!hashValidation || [hashValidation length] == 0) {
                    hashValidation = hashAtPoint;
                }
                
                
                // Validate hash only if needed
                if (!hashValidation) {
                    
                    
                    // perform action TAP in main thread
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        MyLog(@"  [Phase #%d] type = %@, delay = %.2f; (validation SKIPPED) coordinate = (%d, %d)",
                              phaseIndex,
                              actionType,
                              actionDelay,
                              (int)tapCoord.x,
                              (int)tapCoord.y
                              );
                        
                        
                        // do it!
                        [OBTouchRocket tapAtPoint:tapCoord];
                        
                    });
                    
                    
                }
                else {
                    
                    
                    // perform hash validation and action TAP in main thread
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        // get current hash
                        NSString *hashToValidate = computeHashOfViewHierarchyAtPoint(tapCoord, refWindow);
                        if (![hashToValidate isEqualToString:hashValidation]) {
                            
                            MyLog(@"  [Phase #%d] type = %@, delay = %.2f; (hash = %@, INVALID) coordinate = (%d, %d)",
                                  phaseIndex,
                                  actionType,
                                  actionDelay,
                                  hashToValidate,
                                  (int)tapCoord.x,
                                  (int)tapCoord.y
                                  );
                            
                            // skip: hash not validated
                            return;
                            
                        }
                        
                        MyLog(@"  [Phase #%d] type = %@, delay = %.2f; (hash = %@, VALID) coordinate = (%d, %d)",
                              phaseIndex,
                              actionType,
                              actionDelay,
                              hashToValidate,
                              (int)tapCoord.x,
                              (int)tapCoord.y
                              );
                        
                        // validated, do it!
                        [OBTouchRocket tapAtPoint:tapCoord];
                        
                    });
                    
                    
                }
                
                
            }
            
            // TODO: other action types...
            
            
            phaseIndex++;
        }
        
        // Task finished, unlock
        dispatch_async(dispatch_get_main_queue(), ^{
            pthread_mutex_unlock(&_$serialActionLock);
        });
        
    });
    
    return YES;
    
}


#pragma mark - Hash Computing


/**
 * Find the top-most window in current application.
 *
 * @returns The top-most window in current application.
 */
UIWindow *applicationTopMostWindow() {
    
    UIApplication *sharedApplication = [UIApplication sharedApplication];
    NSArray <UIWindow *> *allWindows = [sharedApplication windows];
    
    assert(allWindows.count > 0);
    
    if (allWindows.count == 1) {
        return [allWindows lastObject];
    }
    
    UIWindow *topWindow = nil;
    for (UIWindow *window in [allWindows reverseObjectEnumerator]) {
        if (window.isKeyWindow || !window.isHidden) {
            topWindow = window;
            break;
        }
    }
    
    assert(topWindow != nil);
    
    return topWindow;
    
}


/**
 * Compute hash of view hierarchy at a point before sending touch events.
 *
 * @param point A coordinate to find the top-most view for hierarchy analysing.
 * @param refWindow The window where the point resides in.
 *
 * @returns the computed hash
 */
NSString *computeHashOfViewHierarchyAtPoint(CGPoint point, UIWindow *refWindow) {
    assert([NSThread isMainThread]);
    
    // Get top-most UIView at point
    UIWindow *topWindow = refWindow ?: applicationTopMostWindow();
    UIView *topView = [topWindow ob_viewAtPoint:point];
    
    return computeHashOfViewHierarchy(topView);
}


/**
 * Compute hash of view hierarchy for hash matching.
 *
 * @param topView The top-most view for hierarchy analysing.
 *
 * @returns the computed hash
 */
NSString *computeHashOfViewHierarchy(UIView *topView) {
    assert([NSThread isMainThread]);
    assert(topView != nil);
    
    NSArray <UIView *> *superviews = [topView ob_superviews];
    
    // Generate hierarchy logs to calculate hash
#if DEBUG
    NSMutableString *hierarchyLogs = [NSMutableString stringWithString:@"\n[\n"];
#endif
    
    NSMutableString *hierarchyShortLogs = [NSMutableString string];
    for (UIView *view in superviews) {

#if DEBUG
        NSString *log = nil;
        if ([view respondsToSelector:@selector(ob_description)]) {
            log = [view ob_description];
        } else {
            log = [view description];
        }
        if (log) {
            [hierarchyLogs appendFormat:@"    \"%@\",\n", log];
        }
#endif
        
        NSString *shortLog = nil;
        if ([view respondsToSelector:@selector(ob_shortDescription)]) {
            shortLog = [view ob_shortDescription];
        }
        if (shortLog) {
            [hierarchyShortLogs appendString:shortLog];
            [hierarchyShortLogs appendString:@"\n"];
        }
        
    }
    
    // Use SHA-1 as its hash
    NSString *hash = [hierarchyShortLogs ob_sha1];
    
#if DEBUG
    [hierarchyLogs appendString:@"]"];
    MyLog(@"HIERARCHY = %@\nHASH = %@", hierarchyLogs, hash);
#endif
    
    return hash;
}


#pragma mark - Constructor

__attribute__((constructor))
static void __octobass_initialize()
{
    
    
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
    prepareOBClassRepresentation([clsDetector representationOfClass:[UIView class]]);
    
    // FIXME: Download hash table
    _$viewHashesAndActions = [NSMutableDictionary dictionaryWithDictionary:@{
        
    }];
    
    
    // Hook view methods.
    MyHookMessage([WKWebView class], @selector(initWithFrame:configuration:), (IMP)repl_WKWebView_initWithFrame_configuration_, (IMP *)&orig_WKWebView_initWithFrame_configuration_);
    
#if DEBUG
    MyHookMessage([UIApplication class], @selector(sendEvent:), (IMP)repl_UIApplication_sendEvent_, (IMP *)&orig_UIApplication_sendEvent_);
#endif
    
    
    // Prepare dispatch queue.
    _$serialActionQueue = dispatch_queue_create("com.octobass.queue.serial-action", NULL);
    
    
    // Begin main loop.
    dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(source, dispatch_walltime(NULL, 0), 0.5 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(source, ^{
        
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        BOOL detected = NO;
        
        if (!detected) {
            detected = serialProcessViewAtPoint(CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMinY(screenBounds) + 64.0));
        }
        
        if (!detected) {
            detected = serialProcessViewAtPoint(CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMaxY(screenBounds) - 64.0));
        }
        
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_resume(source);
    });
    
    
}

