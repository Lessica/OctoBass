//
//  OBAppController.m
//  OctoBass
//

#import "OBAppController.h"
#import "OBViewInjector.h"
#import "OBTouchRocket.h"


@interface OBAppController ()

@property (nonatomic, strong) OBViewInjector *viewInjector;

@end


@implementation OBAppController

- (instancetype)init {
    self = [super init];
    if (self) {
        
        // Initialize new view injectors.
        _viewInjector = [[OBViewInjector alloc] init];
        
    }
    return self;
}

- (void)hostApplicationDidBecomeActive:(UIApplication *)application {
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger fingerID = [OBTouchRocket availableFinger];
        [OBTouchRocket touchWithFinger:fingerID atPoint:CGPointMake(204, 415.5) withPhase:UITouchPhaseBegan];
        [OBTouchRocket touchWithFinger:fingerID atPoint:CGPointMake(204, 415.5) withPhase:UITouchPhaseEnded];
    });
    
}

@end

