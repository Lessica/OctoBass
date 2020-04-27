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
    
}

@end

