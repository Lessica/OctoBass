//
//  OBLocalDelegate.m
//  OctoBass
//
//  Created by Darwin on 4/24/20.
//

#import "OBLocalDelegate.h"
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


@implementation OBLocalDelegate


#pragma mark - Initialize

+ (instancetype)localDelegate {
    static OBLocalDelegate *ctor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ctor = [[OBLocalDelegate alloc] init];
    });
    return ctor;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _appController = [[OBAppController alloc] init];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        // app-level
        [center addObserver:self selector:@selector(hostApplicationDidBecomeActive:)         name:UIApplicationDidBecomeActiveNotification         object:nil];
        [center addObserver:self selector:@selector(hostApplicationWillResignActive:)        name:UIApplicationWillResignActiveNotification        object:nil];
        [center addObserver:self selector:@selector(hostApplicationDidEnterBackground:)      name:UIApplicationDidEnterBackgroundNotification      object:nil];
        [center addObserver:self selector:@selector(hostApplicationWillEnterForeground:)     name:UIApplicationWillEnterForegroundNotification     object:nil];
        [center addObserver:self selector:@selector(hostApplicationWillTerminate:)           name:UIApplicationWillTerminateNotification           object:nil];
        [center addObserver:self selector:@selector(hostApplicationDidReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        // window-level
        [center addObserver:self selector:@selector(hostApplicationWindowDidBecomeVisible:)  name:UIWindowDidBecomeVisibleNotification             object:nil];
        [center addObserver:self selector:@selector(hostApplicationWindowDidBecomeHidden:)   name:UIWindowDidBecomeHiddenNotification              object:nil];
        [center addObserver:self selector:@selector(hostApplicationWindowDidBecomeKey:)      name:UIWindowDidBecomeKeyNotification                 object:nil];
        [center addObserver:self selector:@selector(hostApplicationWindowDidResignKey:)      name:UIWindowDidResignKeyNotification                 object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {}


#pragma mark - App-Level Notifications

- (void)hostApplicationDidBecomeActive:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationDidBecomeActive:)])
        [self.appController hostApplicationDidBecomeActive:(UIApplication *)aNotification.object];
}

- (void)hostApplicationWillResignActive:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWillResignActive:)])
        [self.appController hostApplicationWillResignActive:(UIApplication *)aNotification.object];
}

- (void)hostApplicationDidEnterBackground:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationDidEnterBackground:)])
        [self.appController hostApplicationDidEnterBackground:(UIApplication *)aNotification.object];
}

- (void)hostApplicationWillEnterForeground:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWillEnterForeground:)])
        [self.appController hostApplicationWillEnterForeground:(UIApplication *)aNotification.object];
}

- (void)hostApplicationWillTerminate:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWillTerminate:)])
        [self.appController hostApplicationWillTerminate:(UIApplication *)aNotification.object];
}

- (void)hostApplicationDidReceiveMemoryWarning:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationDidReceiveMemoryWarning:)])
        [self.appController hostApplicationDidReceiveMemoryWarning:(UIApplication *)aNotification.object];
}


#pragma mark - Window-Level Notifications

- (void)hostApplicationWindowDidBecomeVisible:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWindowDidBecomeVisible:)])
        [self.appController hostApplicationWindowDidBecomeVisible:(UIWindow *)aNotification.object];
}

- (void)hostApplicationWindowDidBecomeHidden:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWindowDidBecomeHidden:)])
        [self.appController hostApplicationWindowDidBecomeHidden:(UIWindow *)aNotification.object];
}

- (void)hostApplicationWindowDidBecomeKey:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWindowDidBecomeKey:)])
        [self.appController hostApplicationWindowDidBecomeKey:(UIWindow *)aNotification.object];
}

- (void)hostApplicationWindowDidResignKey:(NSNotification *)aNotification {
    if ([self.appController respondsToSelector:@selector(hostApplicationWindowDidResignKey:)])
        [self.appController hostApplicationWindowDidResignKey:(UIWindow *)aNotification.object];
}


@end

__attribute__((constructor))
static void __octobass_initialize()
{
    [[OBLocalDelegate localDelegate] setup];
}

