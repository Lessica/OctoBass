//
//  OctoBass.m
//  OctoBass
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <WebKit/WebKit.h>
#import <pthread.h>
#import <sys/time.h>

#import "MyCHHook.h"
#import "LoadableCategory.h"

#import "OBClassHierarchyDetector.h"
#import "OBTouchRocket.h"
#import "OBWKWebViewMsgProxy.h"

#import "UIView+Hierarchy.h"
#import "UIWindow+Hierarchy.h"
#import "UIWebView+Inspector.h"
#import "WKWebView+Inspector.h"
#import "UIView+Description.h"
#import "UIWebView+Description.h"
#import "WKWebView+Description.h"
#import "NSString+Hashes.h"


MAKE_CATEGORIES_LOADABLE(OctoBass);


#pragma mark - Global Variables

static NSMutableSet <NSString *> *_$clsNames = nil;
static NSMutableDictionary <NSString *, NSDictionary *> *_$viewHashesAndActions = nil;


#pragma mark - WebView Payload


NS_INLINE NSString *ob_webViewPayloadJavaScript()
{
    
    static NSString *payloadJS = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        NSBundle *resBundle = nil;
        
        // Static linking
        if (!resBundle) {
            resBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"OctoBass" ofType:@"bundle"]];
        }
        
        // Dynamic linking
        if (!resBundle) {
            resBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[OBClassHierarchyDetector class]] pathForResource:@"OctoBass" ofType:@"bundle"]];
        }
        
        NSString *jsPath = [resBundle pathForResource:@"webinspectord" ofType:@"js"];
        if (!jsPath) {
            return;
        }
        
        NSData *jsData = [[NSData alloc] initWithContentsOfFile:jsPath];
        if (!jsData) {
            return;
        }
        
        payloadJS = [[NSString alloc] initWithData:jsData encoding:NSUTF8StringEncoding];
        
    });
    
    return payloadJS;
    
}


#pragma mark - WKWebView Methods


NS_INLINE void modifyWKWebViewConfiguration(WKWebViewConfiguration *configuration)
{
    
    NSString *payload = ob_webViewPayloadJavaScript();
    if (!payload.length) {
        return;
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
        if ([script.source isEqualToString:payload]) {
            alreadyInjected = YES;
            break;
        }
    }
    
    
    // Inject if needed.
    if (!alreadyInjected) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:payload injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userContentController addUserScript:userScript];
    }
}


static WKWebView *(*orig_WKWebView_initWithCoder_)(WKWebView *, SEL, NSCoder *);
static WKWebView *repl_WKWebView_initWithCoder_(WKWebView *self, SEL _cmd, NSCoder *coder)
{
    WKWebView *obj = orig_WKWebView_initWithCoder_(self, _cmd, coder);
    modifyWKWebViewConfiguration(self.configuration);
    return obj;
}


static WKWebView *(*orig_WKWebView_initWithFrame_configuration_)(WKWebView *, SEL, CGRect, WKWebViewConfiguration *);
static WKWebView *repl_WKWebView_initWithFrame_configuration_(WKWebView *self, SEL _cmd, CGRect frame, WKWebViewConfiguration *configuration)
{
    modifyWKWebViewConfiguration(configuration);
    return orig_WKWebView_initWithFrame_configuration_(self, _cmd, frame, configuration);
}


#pragma mark - UIWebView Methods

#if ENABLE_UIWEBVIEW

static void (*orig_UIWebViewDelegate_webViewDidFinishLoad_)(id, SEL, UIWebView *);
static void repl_UIWebViewDelegate_webViewDidFinishLoad_(id self, SEL _cmd, UIWebView *webView)
{
    
    NSString *payload = ob_webViewPayloadJavaScript();
    if (!payload.length) {
        if (orig_UIWebViewDelegate_webViewDidFinishLoad_) {
            orig_UIWebViewDelegate_webViewDidFinishLoad_(self, _cmd, webView);
        }
        return;
    }
    
    NSString *evaluatedResult = [webView stringByEvaluatingJavaScriptFromString:payload];
    if (evaluatedResult.length) {
        
        // Save reported hash directly to UIWebView instance
        [webView ob_setInspectorReportedHash:evaluatedResult];
        
    }
    
    if (orig_UIWebViewDelegate_webViewDidFinishLoad_) {
        orig_UIWebViewDelegate_webViewDidFinishLoad_(self, _cmd, webView);
    }
    
}


@interface OBUIWebViewDelegateProxy : NSObject <UIWebViewDelegate>
@end
@implementation OBUIWebViewDelegateProxy
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    repl_UIWebViewDelegate_webViewDidFinishLoad_(self, _cmd, webView);
}
@end


NS_INLINE OBUIWebViewDelegateProxy *ob_uiWebViewDelegateProxy()
{
    
    static OBUIWebViewDelegateProxy *proxy = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        proxy = [[OBUIWebViewDelegateProxy alloc] init];
    });
    
    return proxy;
    
}


static UIWebView *(*orig_UIWebView_initWithFrame_)(UIWebView *, SEL, CGRect);
static UIWebView *repl_UIWebView_initWithFrame_(UIWebView *self, SEL _cmd, CGRect frame)
{
    UIWebView *obj = orig_UIWebView_initWithFrame_(self, _cmd, frame);
    obj.delegate = ob_uiWebViewDelegateProxy();
    return obj;
}


static UIWebView *(*orig_UIWebView_initWithCoder_)(UIWebView *, SEL, NSCoder *);
static UIWebView *repl_UIWebView_initWithCoder_(UIWebView *self, SEL _cmd, NSCoder *coder)
{
    UIWebView *obj = orig_UIWebView_initWithCoder_(self, _cmd, coder);
    obj.delegate = ob_uiWebViewDelegateProxy();
    return obj;
}

#endif  // ENABLE_UIWEBVIEW


#pragma mark - Event Logging


static void (*orig_UIApplication_sendEvent_)(UIApplication *, SEL, UIEvent *);
static void repl_UIApplication_sendEvent_(UIApplication *self, SEL _cmd, UIEvent *event)
{
    
    orig_UIApplication_sendEvent_(self, _cmd, event);
    
    // Only detects single touch object.
    if (event.allTouches.count >= 1) {
        
        // Get the only touch object.
        UITouch *touchObj = [event.allTouches anyObject];
        
        // TAP: began -> ended
        if (touchObj.phase == UITouchPhaseEnded) {
            
            // Get location in its window coordinate.
            CGPoint locInWindow = [touchObj locationInView:nil];
            MyLog(@"[TAPPED] coordinate = (%d, %d)", (int)locInWindow.x, (int)locInWindow.y);
            
#if DEBUG
            
            // Tests of WebView.
            UIView *tappedView = [touchObj.window ob_viewAtPoint:locInWindow];
            NSArray <UIView *> *tappedSuperviews = [tappedView ob_superviews];
            
            UIView *theWebView = nil;
            for (UIView *theView in tappedSuperviews) {
                if ([theView isKindOfClass:[WKWebView class]]) {
                    theWebView = theView;
                    break;
                }
#if ENABLE_UIWEBVIEW
                else if ([theView isKindOfClass:[UIWebView class]]) {
                    theWebView = theView;
                    break;
                }
#endif  // ENABLE_UIWEBVIEW
            }
            
            // Get location in the view's coordinate.
            CGPoint locInView = [theWebView convertPoint:locInWindow fromView:nil];
            
            if ([theWebView isKindOfClass:[WKWebView class]]) {
                WKWebView *wkWebView = (WKWebView *)theWebView;
                
                do {
                    
                    // Coordinate -> DOM selector.
                    NSString *elementSelector = [wkWebView ob_getElementSelectorByViewPortPoint:locInView shouldHighlight:YES];
                    if (!elementSelector) {
                        break;
                    }
                    MyLog(@"    - DOM selector = %@", elementSelector);
                    
                    // DOM selector -> Rect.
                    CGRect rectInView = [wkWebView ob_getViewPortRectByElementSelector:elementSelector shouldScrollTo:YES];
                    if (CGRectIsNull(rectInView)) {
                        break;
                    }
                    CGRect rectInWindow = [wkWebView convertRect:rectInView toView:nil];
                    MyLog(@"    - DOM rect = %@", [NSValue valueWithCGRect:rectInWindow]);
                    
                } while (0);
            }
#if ENABLE_UIWEBVIEW
            else if ([theWebView isKindOfClass:[UIWebView class]]) {
                UIWebView *uiWebView = (UIWebView *)theWebView;
                
                do {
                    
                    // Coordinate -> DOM selector.
                    NSString *elementSelector = [uiWebView ob_getElementSelectorByViewPortPoint:locInView shouldHighlight:YES];
                    if (!elementSelector) {
                        break;
                    }
                    MyLog(@"    - DOM selector = %@", elementSelector);
                    
                    // DOM selector -> Rect.
                    CGRect rectInView = [uiWebView ob_getViewPortRectByElementSelector:elementSelector shouldScrollTo:YES];
                    if (CGRectIsNull(rectInView)) {
                        break;
                    }
                    CGRect rectInWindow = [uiWebView convertRect:rectInView toView:nil];
                    MyLog(@"    - DOM rect = %@", [NSValue valueWithCGRect:rectInWindow]);
                    
                } while (0);
            }
#endif  // ENABLE_UIWEBVIEW
            
#endif  // DEBUG
            
            
        }
        
    }
    
}


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
    UIView *topView = [topWindow ob_viewAtPoint:point];
    if (!topView || topView == topWindow) { return NO; }
    return serialProcessView(topView);
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
    return [[UIApplication sharedApplication] keyWindow];
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
#endif  // DEBUG
    
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
#endif  // DEBUG
        
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
#endif  // DEBUG
    
    return hash;
}


#pragma mark - Constructor

__attribute__((constructor(-1)))
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
    _$viewHashesAndActions = [NSMutableDictionary dictionaryWithDictionary:@{}];
    
    
    // Hook instance methods.
    MyHookMessage([WKWebView class], @selector(initWithFrame:configuration:), (IMP)repl_WKWebView_initWithFrame_configuration_, (IMP *)&orig_WKWebView_initWithFrame_configuration_);
    MyHookMessage([WKWebView class], @selector(initWithCoder:), (IMP)repl_WKWebView_initWithCoder_, (IMP *)&orig_WKWebView_initWithCoder_);
    MyHookMessage([UIApplication class], @selector(sendEvent:), (IMP)repl_UIApplication_sendEvent_, (IMP *)&orig_UIApplication_sendEvent_);
    
    
#if ENABLE_UIWEBVIEW
    // Hook or add delegate methods.
    BOOL delegateExists = NO;
    
    int numClasses = 0;
    int newNumClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    while (numClasses < newNumClasses) {
        
        numClasses = newNumClasses;
        classes = (Class *)realloc(classes, sizeof(Class) * numClasses);
        newNumClasses = objc_getClassList(classes, numClasses);
        
        for (int i = 0; i < numClasses; i++) {
            
            Class clazz = classes[i];
            if (clazz == [OBUIWebViewDelegateProxy class]) {
                continue;
            }
            
            Protocol *legacyDelegate = NSProtocolFromString([NSString stringWithFormat:@"UI%@Delegate", @"WebView"]);
            if (class_conformsToProtocol(clazz, legacyDelegate)) {
                
                delegateExists = YES;
                SEL didFinishLoadSelector = @selector(webViewDidFinishLoad:);
                
                BOOL delegateMethodExists = MyHookMessage(clazz, didFinishLoadSelector, (IMP)repl_UIWebViewDelegate_webViewDidFinishLoad_, (IMP *)&orig_UIWebViewDelegate_webViewDidFinishLoad_);
                if (!delegateMethodExists) {
                    orig_UIWebViewDelegate_webViewDidFinishLoad_ = NULL;
                    
                    BOOL delegateMethodAdded = class_addMethod(clazz, didFinishLoadSelector, (IMP)repl_UIWebViewDelegate_webViewDidFinishLoad_, "v24@0:8@16");
                    assert(delegateMethodAdded);
                }
                
            }
        }
        
    }
    
    free(classes);
    
    // Use delegate proxy instead.
    if (!delegateExists) {
        orig_UIWebViewDelegate_webViewDidFinishLoad_ = NULL;
        
        MyHookMessage([UIWebView class], @selector(initWithFrame:), (IMP)repl_UIWebView_initWithFrame_, (IMP *)&orig_UIWebView_initWithFrame_);
        MyHookMessage([UIWebView class], @selector(initWithCoder:), (IMP)repl_UIWebView_initWithCoder_, (IMP *)&orig_UIWebView_initWithCoder_);
    }
#endif  // ENABLE_UIWEBVIEW
    
    
    // Setup dispatch queue.
    _$serialActionQueue = dispatch_queue_create("com.octobass.queue.serial-action", NULL);
    
    
    // Setup constants.
#if DEBUG
    static NSTimeInterval _$detectInterval = 60.0;
    static NSTimeInterval _$coolDownInterval = 300.0;
#else
    static NSTimeInterval _$detectInterval = 0.5;
    static NSTimeInterval _$coolDownInterval = 15.0;
#endif  // DEBUG
    
    // Setup major points.
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    static NSArray <NSValue *> *_$majorPoints = nil;
    _$majorPoints = @[
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds))],
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMaxY(screenBounds) - 64.0)],
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMinY(screenBounds) + 64.0)],
    ];
    
    // Setup cool-down interval.
    static struct timeval _$coolDownLastDetectedAt;
    gettimeofday(&_$coolDownLastDetectedAt, NULL);
    
    // Setup main timer source.
    static dispatch_source_t source;
    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(source, dispatch_walltime(NULL, 0), _$detectInterval * NSEC_PER_SEC, 0);
    
    // Setup main timer block.
    dispatch_source_set_event_handler(source, ^{
        
        // Check cool-down interval.
        struct timeval _$coolDownWillDetectAt;
        gettimeofday(&_$coolDownWillDetectAt, NULL);
        NSTimeInterval coolDownInterval = (1000000.0 * (_$coolDownWillDetectAt.tv_sec - _$coolDownLastDetectedAt.tv_sec) + _$coolDownWillDetectAt.tv_usec - _$coolDownLastDetectedAt.tv_usec) / 1000000.0;
        if (coolDownInterval < _$coolDownInterval) {
            return;
        }
        
        // Begin serial process on major points.
        BOOL detected = NO;
        
        for (NSValue *point in _$majorPoints) {
            detected = serialProcessViewAtPoint([point CGPointValue]);
            if (detected) {
                break;
            }
        }
        
        if (detected) {
            _$coolDownLastDetectedAt = _$coolDownWillDetectAt;
        }
        
    });
    
    // Fire main timer.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_$detectInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_resume(source);
    });
    
    
}

