//
//  OBAppController.m
//  OctoBass
//
//  Created by Darwin on 4/25/20.
//

#import "OBAppController.h"
#import "OBClassHierarchyDetector.h"
#import <WebKit/WebKit.h>


@interface OBAppController ()

@property (nonatomic, strong) OBClassHierarchyDetector *clsDetector;

@end


@implementation OBAppController

- (void)hostApplicationDidBecomeActive:(UIApplication *)application {
    
    static dispatch_once_t launchedToken;
    dispatch_once(&launchedToken, ^{
        
        // Returns an array of all of the application’s bundles that represent frameworks.
        NSMutableArray <NSBundle *> *allowedBundles = [NSMutableArray arrayWithObject:[NSBundle mainBundle]];
        [allowedBundles addObjectsFromArray:[NSBundle allFrameworks]];
        [allowedBundles filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSBundle *evaluatedBundle, NSDictionary *bindings) {
            NSString *bundlePath = [evaluatedBundle bundlePath];
            return [bundlePath hasPrefix:@"/var/"] || [bundlePath hasPrefix:@"/private/var/"];
        }]];
        
        // New class hierarchy detector, which caches all objc classes.
        OBClassHierarchyDetector *detector = [[OBClassHierarchyDetector alloc] initWithBundles:allowedBundles];
        _clsDetector = detector;
        
        [detector printHierarchyOfClass:[UIView class] formatterBlock:^NSString *(OBClassRepresentation *clsRepr) { return [NSString stringWithFormat:@"* %@", clsRepr.name]; } indentationString:@"|---"];
        
    });
    
    // app did become active
    
}

@end

