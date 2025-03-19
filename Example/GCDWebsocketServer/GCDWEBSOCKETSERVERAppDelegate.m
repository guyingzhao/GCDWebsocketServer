//
//  GCDWEBSOCKETSERVERAppDelegate.m
//  GCDWebsocketServer
//
//  Created by guyingzhao on 03/15/2025.
//  Copyright (c) 2025 guyingzhao. All rights reserved.
//

#import "GCDWEBSOCKETSERVERAppDelegate.h"
#import "GCDWebsocketServer.h"
#import "GCDWebsocketServerHandler.h"
#import "GCDWebServer/GCDWebServerDataResponse.h"

@implementation GCDWEBSOCKETSERVERAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    GCDWebsocketServer *server = [[GCDWebsocketServer alloc] init];
    [server addWebsocketHandlerForPath:@"/" withProcessBlock:^GCDWebsocketServerHandler * _Nullable(GCDWebsocketServerConnection * _Nonnull conn) {
        return [GCDWebsocketServerHandler handlerWithConn:conn];
    }];
    [server addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [GCDWebServerDataResponse responseWithText:@"ok\n"];
    }];
    NSDictionary *options = @{
        GCDWebServerOption_Port: @(9999),
    };
    NSError *error;
    [server startWithOptions:options error:&error];
    if(error){
        NSLog(@"start server failed for: %@", error);
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
@end
