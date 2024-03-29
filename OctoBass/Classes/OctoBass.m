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
#import "TargetConditionals.h"

#import "OBViewEvents.h"
#import "OBClassHierarchyDetector.h"
#import "OBTouchRocket.h"
#import "OBWKWebViewMsgProxy.h"
#import "OBMediaStatus.h"
#import "OBAVPlayerObserver.h"
#import "OBMPMoviePlayerObserver.h"

#import "UIView+Hierarchy.h"
#import "UIWindow+Hierarchy.h"
#import "UIWebView+Inspector.h"
#import "WKWebView+Inspector.h"
#import "UIView+Description.h"
#import "UIWebView+Description.h"
#import "WKWebView+Description.h"
#import "UIView+Screenshortr.h"
#import "UIImage+Screenshotr.h"

#import "NSString+Hashes.h"
#import "NSURL+QueryDictionary.h"


MAKE_CATEGORIES_LOADABLE(OctoBass);
#define STRINGIFY_METHOD(clazz, selector) ([NSString stringWithFormat:@"- [%@ %@]", NSStringFromClass(clazz), NSStringFromSelector(selector)])


#pragma mark - Global Variables

static NSMutableSet <NSString *> *_$clsNames = nil;
static NSMutableDictionary <NSString *, NSDictionary *> *_$viewHashesAndActions = nil;


#pragma mark - WebView JavaScript Payloads


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
        
        // Payload path
        NSString *jsPath = nil;
        
        // Try minified payload
        if (!jsPath) {
            
            // To minify js, use the command below:
            // uglifyjs --compress --mangle --config-file uglifyjs.json -- OctoBass/Assets/webinspectord.js
            jsPath = [resBundle pathForResource:@"webinspectord.min" ofType:@"js"];
            
        }
        
        // Try original payload
        if (!jsPath) {
            jsPath = [resBundle pathForResource:@"webinspectord" ofType:@"js"];
        }
        
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


#pragma mark - WKWebView Hooks


NS_INLINE void modifyWKWebViewConfiguration(WKWebViewConfiguration *configuration)
{
    
    NSString *payload = ob_webViewPayloadJavaScript();
    if (!payload.length) {
        return;
    }
    
    
    // Get its user content controller.
    WKUserContentController *userContentController = configuration.userContentController;
    
    
    // Add inspector message handlers.
    OBWKWebViewMsgProxy *msgProxy = [[OBWKWebViewMsgProxy alloc] init];
    [userContentController removeScriptMessageHandlerForName:_$proxyHandlerNameReport];
    [userContentController addScriptMessageHandler:msgProxy name:_$proxyHandlerNameReport];
    [userContentController removeScriptMessageHandlerForName:_$proxyHandlerNameNotifyMediaStatus];
    [userContentController addScriptMessageHandler:msgProxy name:_$proxyHandlerNameNotifyMediaStatus];
    
    
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
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:payload injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [userContentController addUserScript:userScript];
    }
    
    
#if DEBUG
    configuration.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = NO;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        configuration.mediaPlaybackRequiresUserAction = YES;
#pragma clang diagnostic pop
    }
#endif  // DEBUG
    
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


#pragma mark - UIWebView Hooks

#if ENABLE_UIWEBVIEW

typedef BOOL (*UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_)(id, SEL, UIWebView *, NSURLRequest *, UIWebViewNavigationType);
typedef void (*UIWebViewDelegate_webViewDidFinishLoad_)(id, SEL, UIWebView *);

static NSMutableDictionary <NSString *, NSValue *> *_$originalDelegateMethods = nil;

static BOOL repl_UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_(id self, SEL _cmd, UIWebView *webView, NSURLRequest *request, UIWebViewNavigationType navigationType)
{
    
    // Get stored original delegate method.
    UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_ orig_UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_ = [(NSValue *)_$originalDelegateMethods[STRINGIFY_METHOD([self class], _cmd)] pointerValue];
    
    // Process special requests.
    if ([request.URL.scheme isEqualToString:@"webinspectord"] && [request.URL.host isEqualToString:@"notify"]) {
        
        // Media Status
        if ([request.URL.path isEqualToString:@"/media_status"]) {
            
            NSDictionary <NSString *, NSString *> *rawVideoDetail = [request.URL ob_queryDictionary];
            
            NSMutableDictionary <NSString *, id> *evaluatedVideoDetail = [NSMutableDictionary dictionaryWithCapacity:rawVideoDetail.count];
            if ([rawVideoDetail[@"currentTime"] isKindOfClass:[NSString class]]) {
                evaluatedVideoDetail[@"currentTime"] = @([rawVideoDetail[@"currentTime"] doubleValue]);
            }
            if ([rawVideoDetail[@"duration"] isKindOfClass:[NSString class]]) {
                evaluatedVideoDetail[@"duration"] = @([rawVideoDetail[@"duration"] doubleValue]);
            }
            if ([rawVideoDetail[@"ended"] isKindOfClass:[NSString class]]) {
                evaluatedVideoDetail[@"ended"] = @([rawVideoDetail[@"ended"] boolValue]);
            }
            if ([rawVideoDetail[@"paused"] isKindOfClass:[NSString class]]) {
                evaluatedVideoDetail[@"paused"] = @([rawVideoDetail[@"paused"] boolValue]);
            }
            if ([rawVideoDetail[@"src"] isKindOfClass:[NSString class]]) {
                evaluatedVideoDetail[@"src"] = rawVideoDetail[@"src"];
            }
            if ([rawVideoDetail[@"type"] isKindOfClass:[NSString class]]) {
                evaluatedVideoDetail[@"type"] = rawVideoDetail[@"type"];
            }
            
            // Save reported video detail dictionary to UIWebView instance.
            [webView ob_setLastMediaStatusDictionary:evaluatedVideoDetail];
            
            // Send a global notification.
            [[NSNotificationCenter defaultCenter] postNotificationName:_$OBNotificationNameMediaStatus object:self userInfo:evaluatedVideoDetail];
            
        }
        
        return NO;
    }
    
    // Call original method.
    if (orig_UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_) {
        return orig_UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_(self, _cmd, webView, request, navigationType);
    }
    
    return NO;
    
}

static void repl_UIWebViewDelegate_webViewDidFinishLoad_(id self, SEL _cmd, UIWebView *webView)
{
    
    // Get stored original delegate method.
    UIWebViewDelegate_webViewDidFinishLoad_ orig_UIWebViewDelegate_webViewDidFinishLoad_ = [(NSValue *)_$originalDelegateMethods[STRINGIFY_METHOD([self class], _cmd)] pointerValue];
    
    NSString *payload = ob_webViewPayloadJavaScript();
    if (!payload.length) {
        if (orig_UIWebViewDelegate_webViewDidFinishLoad_) {
            orig_UIWebViewDelegate_webViewDidFinishLoad_(self, _cmd, webView);
        }
        return;
    }
    
    NSString *evaluatedReport = [webView stringByEvaluatingJavaScriptFromString:payload];
    if (evaluatedReport.length) {
        
        // Save reported hash directly to UIWebView instance.
        [webView ob_setInspectorReportedHash:evaluatedReport];
        
#if DEBUG
        NSLog(@"%@", evaluatedReport);
#endif  // DEBUG
        
    }
    
    // Call original method.
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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    return repl_UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_(self, _cmd, webView, request, navigationType);
}

@end


NS_INLINE OBUIWebViewDelegateProxy *ob_uiWebViewDelegateProxy() {
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
    
#if DEBUG
    obj.allowsInlineMediaPlayback = YES;
    obj.mediaPlaybackRequiresUserAction = YES;
#endif
    
    return obj;
}


static UIWebView *(*orig_UIWebView_initWithCoder_)(UIWebView *, SEL, NSCoder *);
static UIWebView *repl_UIWebView_initWithCoder_(UIWebView *self, SEL _cmd, NSCoder *coder)
{
    UIWebView *obj = orig_UIWebView_initWithCoder_(self, _cmd, coder);
    obj.delegate = ob_uiWebViewDelegateProxy();
    
#if DEBUG
    obj.allowsInlineMediaPlayback = YES;
    obj.mediaPlaybackRequiresUserAction = YES;
#endif
    
    return obj;
}

#endif  // ENABLE_UIWEBVIEW


#pragma mark - AVKit Hooks


static AVPlayer *(*orig_AVPlayer_init)(AVPlayer *, SEL);
static AVPlayer *repl_AVPlayer_init(AVPlayer *self, SEL _cmd)
{
    AVPlayer *obj = orig_AVPlayer_init(self, _cmd);
    [[OBAVPlayerObserver sharedObserver] addObservablePlayer:obj];
    return obj;
}


static void (*orig_AVPlayer_dealloc)(AVPlayer *, SEL);
static void repl_AVPlayer_dealloc(AVPlayer *self, SEL _cmd)
{
    [[OBAVPlayerObserver sharedObserver] removeObservablePlayer:self];
    //orig_AVPlayer_dealloc(self, _cmd);
}


#pragma mark - Touch Events


static void (*orig_UIApplication_sendEvent_)(UIApplication *, SEL, UIEvent *);
static void repl_UIApplication_sendEvent_(UIApplication *self, SEL _cmd, UIEvent *event)
{
    
    orig_UIApplication_sendEvent_(self, _cmd, event);
    
    // Only detects single touch object.
    if (event.allTouches.count >= 1) {
        
        // Get the only touch object.
        UITouch *touchObj = [event.allTouches anyObject];
        
        // Private Ivar: no movement
        double *_movementMagnitudeSquared = CHIvarRef(touchObj, _movementMagnitudeSquared, double);
        double movementMagnitudeSquared = _movementMagnitudeSquared != NULL ? (*_movementMagnitudeSquared) : 0.0;
        
        // Private Ivar: not long press
        NSTimeInterval currentTimestamp = touchObj.timestamp;
        NSTimeInterval *_initialTouchTimestamp = CHIvarRef(touchObj, _initialTouchTimestamp, NSTimeInterval);
        NSTimeInterval initialTouchTimestamp = _initialTouchTimestamp != NULL ? (*_initialTouchTimestamp) : currentTimestamp;
        
        // TAP: phase ended
        if (movementMagnitudeSquared < 0.01 && (currentTimestamp - initialTouchTimestamp) < 0.3 && touchObj.phase == UITouchPhaseEnded)
        {
            
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
                    NSString *elementSelector = [wkWebView ob_getElementSelectorFromPoint:locInView shouldHighlight:YES];
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
                    NSString *elementSelector = [uiWebView ob_getElementSelectorFromPoint:locInView shouldHighlight:YES];
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


// Setup constants.
static NSArray <NSValue *> *    _$majorPoints        = nil;
static CFTimeInterval           _$processInterval    = 0.5;
static CFTimeInterval           _$processLastTick;
static CFTimeInterval           _$coolDownInterval   = 15.0;
static CFTimeInterval           _$coolDownLastTick;
static dispatch_queue_t         _$serialActionQueue;
static pthread_mutex_t          _$serialActionLock   = PTHREAD_MUTEX_INITIALIZER;
static OBMediaStatus *          _$currentMediaStatus = nil;


// Setup Declarations.
static BOOL      serialProcessViewAtPoint         (CGPoint point);  // ->
static BOOL      serialProcessView                (UIView *view);  // ->
static UIWindow *applicationTopMostWindow         (void);
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
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, actionDelay, false);
            
            
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
    
    
    /* ---------------------- Configurations ---------------------- */
    
    // Returns an array of all of the application’s bundles that represent frameworks.
    NSBundle *mainBundle = [NSBundle mainBundle];
#if TARGET_OS_SIMULATOR
    NSString *mainParent = [mainBundle.bundlePath stringByDeletingLastPathComponent];
#endif  // TARGET_OS_SIMULATOR
    
    NSMutableArray <NSBundle *> *allowedBundles = [NSMutableArray arrayWithObject:mainBundle];
    [allowedBundles addObjectsFromArray:[NSBundle allFrameworks]];
    [allowedBundles filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSBundle *evaluatedBundle, NSDictionary *bindings) {
        NSString *bundlePath = [evaluatedBundle bundlePath];
#if TARGET_OS_SIMULATOR
        return [bundlePath hasPrefix:mainParent];
#else   // TARGET_OS_SIMULATOR
        return [bundlePath hasPrefix:@"/var/"] || [bundlePath hasPrefix:@"/private/var/"];
#endif  // !TARGET_OS_SIMULATOR
    }]];
    
    // New class hierarchy detector, which caches all objc classes.
    OBClassHierarchyDetector *clsDetector = [[OBClassHierarchyDetector alloc] initWithBundles:allowedBundles];
    
    // Caches all UIView classes recursively.
    _$clsNames = [NSMutableSet set];
    prepareOBClassRepresentation([clsDetector representationOfClass:[UIView class]]);
    
    // FIXME: Download hash table
    _$viewHashesAndActions = [NSMutableDictionary dictionary];
    
    
    /* ---------------------- Objective-C Method Hooks ---------------------- */
    
    // Hook instance methods.
    MyHookMessage([WKWebView class], @selector(initWithFrame:configuration:), (IMP)repl_WKWebView_initWithFrame_configuration_, (IMP *)&orig_WKWebView_initWithFrame_configuration_);
    MyHookMessage([WKWebView class], @selector(initWithCoder:), (IMP)repl_WKWebView_initWithCoder_, (IMP *)&orig_WKWebView_initWithCoder_);
    MyHookMessage([AVPlayer class], @selector(init), (IMP)repl_AVPlayer_init, (IMP *)&orig_AVPlayer_init);
    MyHookMessage([AVPlayer class], NSSelectorFromString(@"dealloc"), (IMP)repl_AVPlayer_dealloc, (IMP *)&orig_AVPlayer_dealloc);
    MyHookMessage([UIApplication class], @selector(sendEvent:), (IMP)repl_UIApplication_sendEvent_, (IMP *)&orig_UIApplication_sendEvent_);
    
#if ENABLE_UIWEBVIEW
    
    // Prepare delegate method slots.
    _$originalDelegateMethods = [NSMutableDictionary dictionary];
    
    // Hook instance methods.
    MyHookMessage([UIWebView class], @selector(initWithFrame:), (IMP)repl_UIWebView_initWithFrame_, (IMP *)&orig_UIWebView_initWithFrame_);
    MyHookMessage([UIWebView class], @selector(initWithCoder:), (IMP)repl_UIWebView_initWithCoder_, (IMP *)&orig_UIWebView_initWithCoder_);
    
    // Hook or add delegate methods.
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
                
                SEL originalSelector;
                IMP originalIMP;
                IMP replacedIMP;
                BOOL delegateMethodExists;
                
                originalSelector = @selector(webViewDidFinishLoad:);
                originalIMP = NULL;
                replacedIMP = (IMP)repl_UIWebViewDelegate_webViewDidFinishLoad_;
                delegateMethodExists = MyHookMessage(clazz, originalSelector, replacedIMP, &originalIMP);
                if (delegateMethodExists) {
                    if (originalIMP) {
                        // Store original delegate method.
                        _$originalDelegateMethods[STRINGIFY_METHOD(clazz, originalSelector)] = [NSValue valueWithPointer:(void *)originalIMP];
                    }
                } else {
                    BOOL delegateMethodAdded = class_addMethod(clazz, originalSelector, replacedIMP, "v24@0:8@16");
                    assert(delegateMethodAdded);
                }
                
                originalSelector = @selector(webView:shouldStartLoadWithRequest:navigationType:);
                originalIMP = NULL;
                replacedIMP = (IMP)repl_UIWebViewDelegate_webView_shouldStartLoadWithRequest_navigationType_;
                delegateMethodExists = MyHookMessage(clazz, originalSelector, replacedIMP, &originalIMP);
                if (delegateMethodExists) {
                    if (originalIMP) {
                        // Store original delegate method.
                        _$originalDelegateMethods[STRINGIFY_METHOD(clazz, originalSelector)] = [NSValue valueWithPointer:(void *)originalIMP];
                    }
                } else {
                    BOOL delegateMethodAdded = class_addMethod(clazz, originalSelector, (IMP)replacedIMP, "B40@0:8@16@24q32");
                    assert(delegateMethodAdded);
                }
                
            }
        }
        
    }
    
    free(classes);
    
#endif  // ENABLE_UIWEBVIEW
    
    
    /* ---------------------- Global Notifications ---------------------- */
    
    // Setup KVO observation handlers for AVPlayerItem.
    [OBAVPlayerObserver sharedObserver];
    
    
#if ENABLE_MPMOVIEPLAYER
    
    // Setup notification handlers for MPMoviePlayer.
    [OBMPMoviePlayerObserver sharedObserver];
    
#endif  // ENABLE_MPMOVIEPLAYER
    
    
    // Setup global notification handlers.
    [[NSNotificationCenter defaultCenter] addObserverForName:_$OBNotificationNameMediaStatus object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
        // Update current media status in main queue.
        NSDictionary *rawMediaStatus = note.userInfo;
        _$currentMediaStatus = [OBMediaStatus statusWithDictionary:rawMediaStatus];
        
#if DEBUG
        
        NSLog(@"%@", _$currentMediaStatus);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // Find the top-most view controller.
            UIViewController *topCtrl = [[[UIApplication sharedApplication] keyWindow] rootViewController];
            while (topCtrl.presentedViewController) {
                topCtrl = topCtrl.presentedViewController;
            }
            if ([topCtrl isKindOfClass:[UIAlertController class]]) {
                return;
            }
            
            // Take a snapshot!
            //UIImage *shotrImage = [applicationTopMostWindow() ob_snapshotr];
            //[shotrImage ob_saveToCameraRoll];
            
            // Build an alert for test.
            UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:@"OctoBass Media Observer" message:nil preferredStyle:UIAlertControllerStyleAlert];
            
            NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
            paraStyle.alignment = NSTextAlignmentLeft;
            NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:[_$currentMediaStatus description] attributes:@{
                NSParagraphStyleAttributeName: paraStyle,
                NSFontAttributeName: [UIFont systemFontOfSize:13.0],
            }];
            [alertCtrl setValue:attrStr forKey:@"attributedMessage"];
            
            [alertCtrl addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [topCtrl presentViewController:alertCtrl animated:YES completion:nil];
            
        });
        
#endif
        
    }];
    
    
    /* ---------------------- Operation Queues ---------------------- */
    
    // Setup cool-down interval.
    _$processLastTick = CACurrentMediaTime();
    _$coolDownLastTick = _$processLastTick;
    
    // Setup major points.
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    _$majorPoints = @[
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMidY(screenBounds))],
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMaxY(screenBounds) - 64.0)],
        [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(screenBounds), CGRectGetMinY(screenBounds) + 64.0)],
    ];
    
    // Setup serial dispatch queue for action/process (background priority).
    _$serialActionQueue = dispatch_queue_create("com.octobass.queue.serial-action", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_BACKGROUND, 0));
    
    // Setup idle handlers for main run loop.
    id mainHandler = ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:
                // About to enter the processing loop. Happens
                // once per `CFRunLoopRun` or `CFRunLoopRunInMode` call
                break;
            case kCFRunLoopBeforeTimers:
            case kCFRunLoopBeforeSources:
                // Happens before timers or sources are about to be handled
                break;
            case kCFRunLoopBeforeWaiting: {
                // All timers and sources are handled and loop is about to go
                // to sleep. This is most likely what you are looking for :)
                
                // i.e. mach_absolute_time().
                CFTimeInterval currentTick = CACurrentMediaTime();
                
                // Check process interval.
                CFTimeInterval processInterval = currentTick - _$processLastTick;
                if (processInterval < _$processInterval) { break; }
                
                // Check cool-down interval.
                CFTimeInterval coolDownInterval = currentTick - _$coolDownLastTick;
                if (coolDownInterval < _$coolDownInterval) { break; }
                
                // Begin serial process on major points.
                BOOL detected = NO;
                for (NSValue *point in _$majorPoints) {
                    detected = serialProcessViewAtPoint([point CGPointValue]);
                    if (detected) {
                        break;
                    }
                }
                
                // Record current ticks.
                _$processLastTick = currentTick;
                if (detected) {
                    _$coolDownLastTick = currentTick;
                }
                
                break;
            }
            case kCFRunLoopAfterWaiting:
                // About to process a timer or source
                break;
            case kCFRunLoopExit:
                // The `CFRunLoopRun` or `CFRunLoopRunInMode` call is about to
                // return
                break;
            default: break;
        }
    };
    CFRunLoopObserverRef mainObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting /* kCFRunLoopAllActivities */, true, 0 /* order */, mainHandler);
    CFRunLoopAddObserver([[NSRunLoop mainRunLoop] getCFRunLoop], mainObserver, kCFRunLoopCommonModes);
    CFRelease(mainObserver);
    
    
}

