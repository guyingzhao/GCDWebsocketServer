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
    return rsp;
}

- (NSError*)readBytes:(NSMutableData*)data withLength:(size_t)length{
    __block NSError *err = nil;
    NSNumber *priorityNum = (NSNumber*)[self.server valueForKey:@"dispatchQueuePriority"];
    intptr_t priority = (intptr_t)[priorityNum longValue];
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_queue_global_t queue =dispatch_get_global_queue(priority, 0);
    dispatch_read(_wsSocket, length, queue, ^(dispatch_data_t buffer, int error) {
        @autoreleasepool {
            if (error == 0) {
                size_t size = dispatch_data_get_size(buffer);
                if (size > 0) {
                    dispatch_data_apply(buffer, ^bool(dispatch_data_t region, size_t chunkOffset, const void* chunkBytes, size_t chunkSize) {
                        [data appendBytes:chunkBytes length:chunkSize];
                        return YES;
                    });
                }
            } else {
                NSString *msg = [NSString stringWithFormat:@"%s", strerror(error)];
                err = [NSError errorWithDomain:@"Socket" code:-1 userInfo:@{@"reason": msg}];
            }
        }
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * 1e9));
    return err;
}

- (NSError*)sendBytes:(NSData*)data{
    NSNumber *priorityNum = (NSNumber*)[self.server valueForKey:@"dispatchQueuePriority"];
    intptr_t priority = (intptr_t)[priorityNum longValue];
    dispatch_data_t buffer = dispatch_data_create(data.bytes, data.length, dispatch_get_global_queue(priority, 0), ^{
      [data self];  // Keeps ARC from releasing data too early
    });
    __block NSError *err = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_write(_wsSocket, buffer, dispatch_get_global_queue(priority, 0), ^(dispatch_data_t remainingData, int error) {
        @autoreleasepool {
            if (error == 0) {
                if(remainingData != NULL){
                    err = [NSError errorWithDomain:@"Socket" code:-1 userInfo:@{@"reason": @"unexpected bytes left"}];
                }
            } else {
                NSString *msg = [NSString stringWithFormat:@"%s", strerror(error)];
                err = [NSError errorWithDomain:@"Socket" code:-1 userInfo:@{@"reason": msg}];
            }
        }
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 30 * 1e9));
    return err;
}
@end
