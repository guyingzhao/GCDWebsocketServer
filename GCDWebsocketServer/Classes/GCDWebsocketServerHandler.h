//
//  GCDWebsocketServerHandler.h
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/16.
//

#import <Foundation/Foundation.h>
#import "GCDWebsocketServerConnection.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WebSocketOpcode) {
    OPCODE_CONTINUATION = 0x0,
    OPCODE_TEXT = 0x1,
    OPCODE_BINARY = 0x2,
    OPCODE_CLOSE = 0x8,
    OPCODE_PING = 0x9,
    OPCODE_PONG = 0xA
};

@interface GCDWebsocketServerHandler : NSObject

@property (nonnull, strong) GCDWebsocketServerConnection *conn;

@property (readonly, atomic) BOOL closed;

+(instancetype)handlerWithConn:(GCDWebsocketServerConnection*)conn;

-(void)close;

-(void)onConnected;

-(void)onClosed;

-(void)onError:(NSError*)error;

-(void)onData:(NSData*)data;

-(void)onText:(NSString*)text;

-(void)onPing:(NSString*)msg;

-(void)onPong:(NSString*)msg;

-(BOOL)handleMessage;

-(void)sendData:(NSData*)data opcode:(WebSocketOpcode)code;

-(void)sendText:(NSString*)text;

@end

NS_ASSUME_NONNULL_END
