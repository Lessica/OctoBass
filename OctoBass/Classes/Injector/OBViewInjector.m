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
            
            if ([clsName isEqualToString:@"BUNativeExpressAdView"]) {
                
                // tap its center after 3 seconds
                
                // BUNativeExpressAdView <- BUWKWebViewClient
                //             UnityView <- BUNativeExpressAdView
                
                CGPoint center = [self convertPoint:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)) toView:nil];
                [OBViewInjector tapAtPoint:center afterInterval:3.0 simpleValidation:YES];
                
            }
            
            else if ([clsName isEqualToString:@"GADWebAdView"]) {  /* UIWebView */
                
                // tap (627, 150) after (video playing)
                
                // GADWebAdView <- GADVideoPlayerView
                // GADWebAdView <- GADTestLabel
                //       UIView <- GADWebAdView
                //       UIView <- GADCloseButton
                
                [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
                    [OBViewInjector tapAtPoint:CGPointMake(315, 75) afterInterval:1.0 simpleValidation:YES];
                    [OBViewInjector tapAtPoint:CGPointMake(233.5, 149) afterInterval:1.0 simpleValidation:YES];
                }];
                
            }
            
            else if ([clsName isEqualToString:@"SupersonicAdsView"]) {  /* WKWebView */
                
                // tap (394, 898) after (video playing)
                
                // SupersonicAdsView <- SSWVWKWebView
                //         UnityView <- SupersonicAdsView
                
                CGPoint point2 = CGPointMake(200, 450);
                [OBViewInjector tapAtPoint:point2 afterInterval:5.0 simpleValidation:YES];
                
            }
            
            else if ([clsName isEqualToString:@"BU_ZFPlayerView"]) {
                
                // BUNativeExpressRewardedVideoAdView <- BUWKWebViewClient
                // UIView <- BURewardedVideoWebDefaultView
                
                // UIView <- BUWKWebViewClient
                // BUWKWebViewClient <- BUWebViewProgressView
                
                // UIView <- BUVideoTopMask
                // UIView <- BUVideoBottomMask
                // UIView <- BURewardedVideoTopBarView
                
                // UIView <- BU_ZFPlayerView
                // BU_ZFPlayerView <- BU_ZFPlayerControlView
                // BU_ZFPlayerControlView <- BU_MMMaterialDesignSpinner
                
                // UIImageView <- BU_ASValueTrackingSlider
                // BU_ASValueTrackingSlider <- BU_ASValuePopUpView
                
                CGPoint point3 = CGPointMake(200, 587);
                [OBViewInjector tapAtPoint:point3 afterInterval:2.0 simpleValidation:YES];
                
            }
            
            // UIWindow <- GADMainWindowView
            // UIWindow <- SSWVWKWebView
            
        } else {
            
            // removed from superview
            MyLog(@"%@ removed from its superview", clsName);
            
            if ([clsName isEqualToString:@"GADWebAdView"]) {  /* UIWebView */
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
            
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


#pragma mark - Validation


+ (void)tapAtPoint:(CGPoint)point afterInterval:(NSTimeInterval)interval simpleValidation:(BOOL)validation
{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        UIView *targetView = validation ? [keyWindow hitTest:point withEvent:nil] : nil;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (validation) {
                UIView *currentView = [keyWindow hitTest:point withEvent:nil];
                if (currentView == targetView) {
                    [OBTouchRocket tapAtPoint:point];
                }
            } else {
                [OBTouchRocket tapAtPoint:point];
            }
        });
    });
    
}


@end

