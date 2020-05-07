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
#import "UIView+Description.h"
#import "UIWebView+Description.h"
#import "WKWebView+Description.h"
#import "NSString+Hashes.h"

#import "OBWKWebViewMsgProxy.h"


@implementation OBViewInjector


#pragma mark - Global Variables

static NSMutableSet <NSString *> *_$clsNames = nil;
static NSMutableDictionary <NSString *, NSDictionary *> *_$viewHashesAndActions = nil;


#pragma mark - UIView Methods


/**
 * - [UIView didMoveToWindow]
 */
static void (*orig_UIView_didMoveToWindow)(UIView *, SEL);
static void repl_UIView_didMoveToWindow(UIView *self, SEL _cmd)
{
    
    do {
        
        
        // Filter: SDK views only
        NSString *clsName = NSStringFromClass([self class]);
        NSString *supClsName = nil;
        if (self.superview != nil) {
            supClsName = NSStringFromClass([self.superview class]);
        }
        
        BOOL hasSDKView = NO;
        if (clsName != nil && [_$clsNames containsObject:clsName]) {
            hasSDKView = YES;
        } else if (supClsName != nil && [_$clsNames containsObject:supClsName]) {
            hasSDKView = YES;
        }
        if (!hasSDKView) {
            break;
        }
        
        
        // Logging: Removed from superview
        if (supClsName == nil) {
            
            MyLog(@"%@ removed from its superview", clsName);
            break;
            
        }
        
        // Do Process
        MyLog(@"%@ moved to %@", clsName, supClsName);
        [OBViewInjector processView:self];
        
        
    } while (0);
    
    
    // Fallback
    orig_UIView_didMoveToWindow(self, _cmd);
    
}


#pragma mark - WKWebView Methods


static WKWebView *(*orig_WKWebView_initWithFrame_configuration_)(WKWebView *, SEL, CGRect, WKWebViewConfiguration *);
static WKWebView *repl_WKWebView_initWithFrame_configuration_(WKWebView *self, SEL _cmd, CGRect frame, WKWebViewConfiguration *configuration)
{
    
    static NSString *inspectorJS = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // FIXME: load inspector js securely
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
        
        // FIXME: Download hash table
        _$viewHashesAndActions = [NSMutableDictionary dictionaryWithDictionary:@{
            
            
            /* Example */
            @"b5c0a556626f6c0a702223a0afae4e41140b7f74": @{
                    @"phases": @[
                            @{
                                
                                @"type": @"TAP",
                                @"delay": @(3.0),
                                //@"hashValidation": @"b5c0a556626f6c0a702223a0afae4e41140b7f74",
                                //@"coordinate": @"!CENTER",
                            },
                            // ...other phases
                    ],
            },
            
            
//            [
//                "<GDTSplashAlignImageView: 0x0x12e818900; frame = (0 0; 375 667)>",
//                "<GDTSplashView: 0x0x12e8184f0; frame = (0 0; 375 667)>",
//                "<UIView: 0x0x12deebf00; frame = (0 0; 375 667)>",
//                "<UITransitionView: 0x0x12e81a7d0; frame = (0 0; 375 667)>",
//                "<UIWindow: 0x0x12bdecb30; frame = (0 0; 375 667)>",
//            ]
            @"aa69b912b267cf504ccec3f2f96beee020ec6309": @{
                    @"phases": @[
                            @{
                                @"type": @"TAP",
                                @"delay": @(1.0),
                            },
                    ],
            },
            
            
//            [
//                "<UIView: 0x0x151901c80; frame = (0 0; 470 240)>",
//                "<UIView: 0x0x151905b50; frame = (0 0; 470 240)>",
//                "<WKContentView: 0x0x15241d600; frame = (0 0; 470 240)>",
//                "<WKScrollView: 0x0x15011e600; frame = (0 0; 375 240)>",
//                "<BUWKWebViewClient: 0x0x152428800; frame = (0 0; 375 240); url = https://sf3-ttcdn-tos.pstatp.com/obj/ad-pattern/renderer/a99335/index.html; hash = 801a3dcdc223695e8015bd37aeec9fd95bb8527a>",
//                "<BUNativeExpressAdView: 0x0x15644cbc0; frame = (0 0; 375 240)>",
//                "<UnityView: 0x0x14fd611f0; frame = (0 0; 375 667)>",
//                "<UIWindow: 0x0x14fd60e60; frame = (0 0; 375 667)>",
//            ]
            @"9dfbfe3260c07f1198c42b8ec2d191c92ef715b5": @{
                    @"phases": @[
                            @{
                                @"type": @"TAP",
                                @"delay": @(1.0),
                            },
                    ],
            },
            
            
//            [
//                "<UIView: 0x0x15346ca40; frame = (0 0; 375 667)>",
//                "<UIView: 0x0x15346cc20; frame = (0 0; 375 667)>",
//                "<WKContentView: 0x0x15210bc00; frame = (0 0; 375 667)>",
//                "<WKScrollView: 0x0x15210c600; frame = (0 0; 375 667)>",
//                "<SSWVWKWebView: 0x0x152109200; frame = (0 0; 375 667); url = file:///var/mobile/Containers/Data/Application/ED0E77C9-504D-4F7D-AF30-5123EE82BCD1/Library/Caches/SSACache_5.61/mobileController/mobileController.html?SDKVersion=5.61&deviceOSVersion=12.4&deviceOs=ios&protocol=https:&domain=scc.ssacdn.com&debug=3&webviewType=wk&controllerConfig=%7B%22applicationKey%22:%22ac2c2105%22,%22webviewType%22:%22wk%22,%22isSecured%22:true%7D; hash = 347625a49d7da3aa32ddf99381f181ffab275b90>",
//                "<SupersonicAdsView: 0x0x1536892d0; frame = (0 0; 375 667)>",
//                "<UIView: 0x0x151ff1820; frame = (0 0; 375 667)>",
//                "<UITransitionView: 0x0x15644f4c0; frame = (0 0; 375 667)>",
//                "<UIWindow: 0x0x14fd60e60; frame = (0 0; 375 667)>",
//            ]
            @"d22c7f381797a1d50ad1445332e8111fda297834": @{
                    @"phases": @[
                            @{
                                @"type": @"TAP",
                                @"delay": @(1.0),
                            },
                    ],
            },
            
            
            // ...other hashes
            
            
        }];
        
        // Hook view methods.
        MyHookMessage([UIView class], @selector(didMoveToWindow), (IMP)repl_UIView_didMoveToWindow, (IMP *)&orig_UIView_didMoveToWindow);
        MyHookMessage([WKWebView class], @selector(initWithFrame:configuration:), (IMP)repl_WKWebView_initWithFrame_configuration_, (IMP *)&orig_WKWebView_initWithFrame_configuration_);
        
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


+ (NSString *)computeHashOfViewHierarchy:(UIView *)topView referenceWindow:(UIWindow *)refWindow {
    
    // Generate hierarchy logs to calculate hash
#if DEBUG
    NSMutableString *hierarchyLogs = [NSMutableString stringWithString:@"\n[\n"];
#endif
    
    NSMutableString *hierarchyShortLogs = [NSMutableString string];
    
    for (UIView *view in [topView ob_superviews]) {
        
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


+ (NSString *)computeHashOfViewHierarchyAtPoint:(CGPoint)point referenceWindow:(UIWindow *)refWindow {
    
    NSAssert([NSThread isMainThread], @"must be called from main thread");
    
    
    // Get top-most UIView at point
    UIView *topView = [refWindow ob_viewAtPoint:point];
    
    
    return [self computeHashOfViewHierarchy:topView referenceWindow:refWindow];
    
}


+ (void)processView:(UIView *)view {
    
    
    // Filter: View is hidden
    if ([view isHidden]) {
        
        MyLog(@"skipped: view is hidden");
        return;
        
    }
    
    
    // Compute hash for view hierarchy at center point
    UIWindow *refWindow = view.window;
    if (!refWindow || refWindow.isHidden) {
        
        MyLog(@"skipped: view has no visible window");
        return;
        
    }
    
    
    CGPoint center = CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds));
    CGPoint pointInWindow = [view convertPoint:center toView:nil];
    NSString *hashAtPoint = [OBViewInjector computeHashOfViewHierarchy:view referenceWindow:refWindow];
    
    
    // Fetch action for hash
    NSDictionary *actionForHash = [_$viewHashesAndActions objectForKey:hashAtPoint];
    
    
    // Filter: No matching hash
    if (!actionForHash) {  /* ![actionForHash isKindOfClass:[NSDictionary class]] */
        
        MyLog(@"skipped: no matching hash %@", hashAtPoint);
        return;
        
    }
    
    
    // Action phases
    NSArray <NSDictionary *> *actionPhases = actionForHash[@"phases"];
    assert([actionPhases isKindOfClass:[NSArray class]]);
    MyLog(@"processing: hash %@", hashAtPoint);
    
    
    // Enumate action phases in a global queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // get current hash
                        NSString *hashToValidate = [OBViewInjector computeHashOfViewHierarchyAtPoint:tapCoord referenceWindow:refWindow];
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
        
    });
    
    
}


@end

