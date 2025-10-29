//
//  GCDWebsocketServerConnection.m
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/15.
//

#import "GCDWebsocketServerConnection.h"
#import "GCDWebsocketServer.h"
#import "GCDWebServer/GCDWebServerErrorResponse.h"
#import "GCDWebsocketServerHandler.h"
#import "GCDWebsocketServerResponse.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation GCDWebsocketServerConnection{
    CFSocketNativeHandle _wsSocket;
    SEL _readSelector;
    SEL _writeSelector;
}

-(bool)open{
    NSNumber *fdValue = (NSNumber*)[self valueForKey:@"_socket"];
    _wsSocket = (CFSocketNativeHandle)[fdValue longValue];
    _readSelector = NSSelectorFromString(@"readData:withLength:completionBlock:");
    _writeSelector = NSSelectorFromString(@"writeData:withCompletionBlock:");
    if(![self respondsToSelector:_readSelector]){
        return NO;
    }
    if(![self respondsToSelector:_writeSelector]){
        return NO;
    }
    return [super open];
}

- (NSString*)makeAcceptKey:(NSString*)key{
    NSString *magicString = @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    NSString *combined = [key stringByAppendingString:magicString];
    NSData *data = [combined dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSData *output = [NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
    return [output base64EncodedStringWithOptions:0];
}

- (nullable GCDWebServerResponse*)preflightRequest:(GCDWebServerRequest*)request{
    NSString *upgrade = [request.headers valueForKey:@"Upgrade"];
    if(![upgrade isEqualToString:@"websocket"]){
        return nil;
    }
    NSError *err = nil;
    if(![self.server isKindOfClass:[GCDWebsocketServer class]]){
        GCDWebServerErrorResponse *rsp = [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"server class=%@ is not a a GCDWebsocketServer", NSStringFromClass([self.server class])];
        return rsp;
    }
    GCDWebsocketServerHandler *handler = [(GCDWebsocketServer*)self.server handlerAtPath:request.path WithConnection:self error:&err];
    if(!handler){
        NSString *msg = @"Unknown";
        if(err){
            msg = [err localizedDescription];
        }
        GCDWebServerErrorResponse *rsp = [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_BadRequest message:@"%@", msg];
        return rsp;
    }
    NSString *websocketKey = [request.headers valueForKey:@"Sec-Websocket-Key"];
    if(!websocketKey || [websocketKey isEqualToString:@""]){
        return nil;
    }
    NSString *acceptKey = [self makeAcceptKey:websocketKey];
    GCDWebsocketServerResponse *rsp = [GCDWebsocketServerResponse responseWithHandler:handler];
    [rsp setStatusCode:101];
    [rsp setValue:@"websocket" forAdditionalHeader:@"Upgrade"];
    [rsp setValue:@"Upgrade" forAdditionalHeader:@"Connection" ];
    [rsp setValue:acceptKey forAdditionalHeader:@"Sec-WebSocket-Accept"];
    SEL sel = NSSelectorFromString(@"_endBackgroundTask");
    if([[NSThread currentThread] isMainThread]){
        [self.server performSelector:sel];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            [self.server performSelector:sel];
        });
    }
    
    return rsp;
}

- (NSError*)readBytes:(NSMutableData*)data withLength:(size_t)length{
    size_t count = 0;
    uint8_t *buf = (uint8_t*)malloc(length);
    NSError *err = nil;
    while(count < length){
        size_t temp = read(_wsSocket, buf + count, length - count);
        if(temp == 0){
            break;
        }
        if(temp < 0){
            NSString *msg = [NSString stringWithFormat:@"read socket %d failed: %s", _wsSocket, strerror((int)temp)];
            err = [NSError errorWithDomain:@"Socket" code:1 userInfo:@{@"error": msg}];
        }
        count += temp;
    }
    [data appendBytes:buf length:length];
    free(buf);
    return err;
}

- (NSError*)_sendBytes:(char*)ptr length:(NSUInteger)length{
    size_t count = 0;
    NSError *err = nil;
    while(count < length){
        size_t temp = write(_wsSocket, ptr + count, length - count);
        if(temp == 0){
            break;
        }
        if(temp < 0){
            NSString *msg = [NSString stringWithFormat:@"write socket %d failed: %s", _wsSocket, strerror((int)temp)];
            err = [NSError errorWithDomain:@"Socket" code:1 userInfo:@{@"error": msg}];
        }
        count += temp;
    }
    return err;
}

-(NSError*)sendBytes:(NSData *)bytes{
    __block NSError *error = nil;
    [bytes enumerateByteRangesUsingBlock:^(const void * _Nonnull ptr, NSRange byteRange, BOOL * _Nonnull stop) {
        [self _sendBytes:(char*)ptr length:byteRange.length];
    }];
    return error;
}
@end
