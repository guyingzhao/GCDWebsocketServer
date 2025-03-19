//
//  GCDWebsocketServerResponse.h
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/15.
//

#import <Foundation/Foundation.h>
#import <GCDWebServer/GCDWebServerResponse.h>
#import "GCDWebsocketServerHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface GCDWebsocketServerResponse : GCDWebServerResponse

+(instancetype)responseWithHandler:(GCDWebsocketServerHandler*)handler;

-(instancetype)initWithHandler:(GCDWebsocketServerHandler*)handler;

-(BOOL)hasBody;

- (void)close;
@end

NS_ASSUME_NONNULL_END
