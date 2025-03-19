//
//  GCDWebsocketServerHandler.h
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/16.
//

#import <Foundation/Foundation.h>
#import "GCDWebsocketServerConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface GCDWebsocketServerHandler : NSObject

@property (nonnull, strong) GCDWebsocketServerConnection *conn;

+(instancetype)handlerWithConn:(GCDWebsocketServerConnection*)conn;

-(void)onConnected;

-(void)onClosed;

-(void)onError:(NSError*)error;

-(void)onData:(NSData*)data;

-(void)onText:(NSString*)text;

-(void)onPing:(NSString*)msg;

-(void)onPong:(NSString*)msg;

-(BOOL)handleMessage;

@end

NS_ASSUME_NONNULL_END
