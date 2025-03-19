//
//  GCDWebsocketServer.m
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/15.
//

#import "GCDWebsocketServer.h"
#import "GCDWebServer/GCDWebServerDataResponse.h"
#import "GCDWebsocketServerConnection.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation GCDWebsocketServer{
    NSMutableDictionary *_websocketHandlers;
}

-(BOOL)startWithOptions:(nullable NSDictionary<NSString *,id> *)options error:(NSError *__autoreleasing  _Nullable *)error{
    NSMutableDictionary *newOptions = nil;
    if(!options){
        newOptions = [NSMutableDictionary dictionaryWithObject:[GCDWebsocketServerConnection class] forKey:GCDWebServerOption_ConnectionClass];
    } else if([options valueForKey:GCDWebServerOption_ConnectionClass]){
        if(error){
            NSString *msg = [NSString stringWithFormat: @"option for key=%@ can't be specified for GCDWebsocketServer", GCDWebServerOption_ConnectionClass];
            *error = [NSError errorWithDomain:@"User" code:-1 userInfo:@{@"message": msg}];
        }
        return NO;
    } else {
        newOptions = [NSMutableDictionary dictionaryWithDictionary:options];
        [newOptions setValue:[GCDWebsocketServerConnection class] forKey:GCDWebServerOption_ConnectionClass];
    }
    return [super startWithOptions:newOptions error:error];
}

- (void)addWebsocketHandlerForPath:(NSString*)path withProcessBlock:(GCDWebsocketServerHandleBlock) block{
    if(!_websocketHandlers){
        _websocketHandlers = [NSMutableDictionary dictionary];
    }
    [_websocketHandlers setValue:block forKey:path];
    [self addHandlerForMethod:@"GET" path:path requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return nil;
    }];
}

-(GCDWebsocketServerHandler*)handlerAtPath:(NSString*)path WithConnection:(GCDWebsocketServerConnection*)conn error:(NSError *__autoreleasing _Nullable *)error{
    GCDWebsocketServerHandleBlock block = [_websocketHandlers valueForKey:path];
    if(block == nil){
        if(error){
            NSString *msg = [NSString stringWithFormat: @"websocket handler at path=%@ not found", path];
            *error = [NSError errorWithDomain:@"User" code:-1 userInfo:@{@"message": msg}];
        }
        return nil;
    }
    return block(conn);
}

@end
