//
//  GCDWebsocketServer.h
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/15.
//

#import <Foundation/Foundation.h>
#import <GCDWebServer/GCDWebServer.h>
#import "GCDWebsocketServerConnection.h"
#import "GCDWebsocketServerHandler.h"

NS_ASSUME_NONNULL_BEGIN
typedef GCDWebsocketServerHandler* _Nullable (^GCDWebsocketServerHandleBlock)(GCDWebsocketServerConnection*);

@interface GCDWebsocketServer : GCDWebServer

- (void)addWebsocketHandlerForPath:(NSString*)path withProcessBlock:(GCDWebsocketServerHandleBlock)block;

-(BOOL)startWithOptions:(nullable NSDictionary<NSString *,id> *)options error:(NSError *__autoreleasing  _Nullable *)error;

-(GCDWebsocketServerHandler*)handlerAtPath:(NSString*)path WithConnection:(GCDWebsocketServerConnection*)conn error:(NSError *__autoreleasing _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
