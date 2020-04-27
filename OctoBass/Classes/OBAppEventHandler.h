//
//  OBAppEventHandler.h
//  OctoBass
//

#ifndef OBAppEventHandler_h
#define OBAppEventHandler_h

@protocol OBAppEventHandler <NSObject>

#pragma mark - App-Level Notifications
@optional
- (void)hostApplicationDidBecomeActive:(UIApplication *)application;
- (void)hostApplicationWillResignActive:(UIApplication *)application;
- (void)hostApplicationDidEnterBackground:(UIApplication *)application;
- (void)hostApplicationWillEnterForeground:(UIApplication *)application;
- (void)hostApplicationWillTerminate:(UIApplication *)application;
- (void)hostApplicationDidReceiveMemoryWarning:(UIApplication *)application;

#pragma mark - Window-Level Notifications
@optional
- (void)hostApplicationWindowDidBecomeVisible:(UIWindow *)window;
- (void)hostApplicationWindowDidBecomeHidden:(UIWindow *)window;
- (void)hostApplicationWindowDidBecomeKey:(UIWindow *)window;
- (void)hostApplicationWindowDidResignKey:(UIWindow *)window;

@end

#endif /* OBAppEventHandler_h */
