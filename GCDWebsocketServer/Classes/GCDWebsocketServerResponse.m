//
//  GCDWebsocketServerResponse.m
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/15.
//

#import "GCDWebsocketServerResponse.h"


@implementation GCDWebsocketServerResponse{
    GCDWebsocketServerHandler *_handler;
}

-(instancetype)initWithHandler:(GCDWebsocketServerHandler*)handler{
    self = [super init];
    _handler = handler;
    
    // adapt to ContentType checking
    [self setContentType:@"websocket"];
    
    // prevent server sending "\0\r\n\r\n" to client
    [self setContentLength:0];
    return self;
}

+(instancetype)responseWithHandler:(GCDWebsocketServerHandler*)handler{
    return [[self alloc] initWithHandler:handler];
}

-(BOOL)hasBody{
    return YES;
}

-(void)onWebsocket{
    // 1. headers are already sent, begin websocket data handling
    [_handler onConnected];
    while([_handler handleMessage]){
        // nothing to do here
    }
    [_handler onClosed];
}

- (void)close{
    [self onWebsocket];
    [super close];
}
@end
