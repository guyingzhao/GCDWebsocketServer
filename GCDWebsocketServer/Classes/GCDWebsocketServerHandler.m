//
//  GCDWebsocketServerHandler.m
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/16.
//

#import "GCDWebsocketServerHandler.h"
#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

// Constants
static const NSUInteger FIN = 0x80;
static const NSUInteger PAYLOAD_LEN = 0x7F;
static const NSUInteger PAYLOAD_LEN_EXT16 = 0x7E;
static const NSUInteger PAYLOAD_LEN_EXT64 = 0x7F;

// Length thresholds
static const NSUInteger LENGTH_7 = 0x7D;
static const NSUInteger LENGTH_16 = (1 << 16);
static const NSUInteger LENGTH_63 = 1 << 63;

static const NSUInteger OPCODE_MASK = 0x0F;
static const NSUInteger MASKED_MASK = 0x80;
static const NSUInteger PAYLOAD_LEN_MASK = 0x7F;


@implementation GCDWebsocketServerHandler

+ (instancetype)handlerWithConn:(GCDWebsocketServerConnection *)conn{
    GCDWebsocketServerHandler *handler = [[[self class] alloc] init];
    handler.conn = conn;
    return handler;
}

-(instancetype)init{
    _closed = NO;
    return [super init];
}

-(void)sendData:(NSData*)data opcode:(WebSocketOpcode)code masked:(BOOL)masked{
    if(_closed){
        return;
    }
    NSUInteger payloadLength = data.length;
    NSMutableData *frame = [NSMutableData data];
    
    // Build header
    uint8_t firstByte = FIN | code;
    [frame appendBytes:&firstByte length:1];
    // Payload length handling
    if (payloadLength < LENGTH_7) {
        uint8_t lenByte = masked ? MASKED_MASK | payloadLength : payloadLength;
        [frame appendBytes:&lenByte length:1];
    }
    else if (payloadLength < LENGTH_16) {
        uint8_t lenByte = masked ? MASKED_MASK | PAYLOAD_LEN_EXT16 : PAYLOAD_LEN_EXT16;
        [frame appendBytes:&lenByte length:1];
        
        uint16_t len = CFSwapInt16HostToBig((uint16_t)payloadLength);
        [frame appendBytes:&len length:2];
    }
    else if (payloadLength < LENGTH_63) {
        uint8_t lenByte = masked ? MASKED_MASK | PAYLOAD_LEN_EXT64 : PAYLOAD_LEN_EXT64;
        [frame appendBytes:&lenByte length:1];
        uint64_t len = CFSwapInt64HostToBig(payloadLength);
        [frame appendBytes:&len length:8];
    } else {
        [NSException raise:@"Message too long"
                    format:@"Message length %lu exceeds maximum", payloadLength];
    }
        
    // Masking handling
    if (masked) {
        // Generate 4-byte mask key
        uint8_t maskKey[4];
        uint8_t* maskKeyPtr = maskKey;
        arc4random_buf(maskKey, 4);
        [frame appendBytes:maskKey length:4];
        
        // Apply mask to payload
        uint8_t *buf = (uint8_t*)malloc(payloadLength);
        [data enumerateByteRangesUsingBlock:^(const void * _Nonnull ptr, NSRange byteRange, BOOL * _Nonnull stop) {
            for(NSUInteger i=0; i<byteRange.length; i++){
                NSUInteger offset = i + byteRange.location;
                buf[offset] = ((uint8_t*)ptr)[i] ^ maskKeyPtr[offset%4];
            }
        }];
        [frame appendBytes:buf length:data.length];
        free(buf);
    } else {
        [frame appendData:data];
    }
    NSError *err = [self.conn sendBytes:frame];
    if(err){
        [self onError:err];
    }
}

-(void)sendText:(NSString*)text{
    [self sendData:[text dataUsingEncoding:NSUTF8StringEncoding] opcode:OPCODE_TEXT masked:YES];
}

-(NSError*)handleMessageWithCode:(WebSocketOpcode)code length:(NSUInteger)payloadLength{
    NSError *err = nil;
    GCDWebsocketServerConnection *conn = self.conn;
    NSMutableData *data = [NSMutableData data];
    if (payloadLength == 126) {
        data = [NSMutableData data];
        err = [conn readBytes:data withLength:2];
        if(err){
            return err;
        }
        payloadLength = CFSwapInt16BigToHost(*((uint16_t*)(data.bytes)));
    } else if (payloadLength == 127) {
        err = [conn readBytes:data withLength:8];
        if(err){
            return err;
        }
        payloadLength = (NSUInteger)CFSwapInt64BigToHost(*((uint64_t*)(data.bytes)));
    }
    NSLog(@"going to recv %lu bytes payload", payloadLength);
    
    // reading mask
    data = [NSMutableData data];
    err = [conn readBytes:data withLength:4];
    if(err){
        return err;
    }
    uint8_t maskBytes[4] = {0};
    uint8_t* maskBytesPtr = maskBytes;
    [data getBytes:maskBytes length:4];
    
    // reading payload and decode
    data = [NSMutableData data];
    err = [conn readBytes:data withLength:payloadLength];
    if(err){
        return err;
    }
    uint8_t *buf = (uint8_t*)malloc(payloadLength);
    [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
        for(NSUInteger i=0; i<byteRange.length; i++){
            NSUInteger offset = i + byteRange.location;
            buf[offset] = ((uint8_t*)bytes)[i] ^ maskBytesPtr[offset%4];
        }
    }];
    NSData *body = [NSData dataWithBytes:buf length:payloadLength];
    free(buf);
    if(code == OPCODE_TEXT){
        NSString *text = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
        [self onText:text];
    } else if(code == OPCODE_BINARY){
        [self onData:body];
    } else if(code == OPCODE_PING){
        [self onPing:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
    } else if(code == OPCODE_PONG){
        [self onPong:[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding]];
    }
    return err;
}


-(BOOL)handleMessage{
    @autoreleasepool {
        GCDWebsocketServerConnection *conn = self.conn;
        NSMutableData *data = [NSMutableData data];
        NSError *err = [conn readBytes:data withLength:2];
        if(err){
            [self onError:err];
            return NO;
        }
        if(data.length == 0){
            // socket is closed
            NSLog(@"websocket's socket closed by client");
            return NO;
        }
        uint8_t *bytes = (uint8_t*)[data bytes];
        uint8_t b1 = (uint8_t)(bytes[0]);
        uint8_t b2 = (uint8_t)(bytes[1]);
        WebSocketOpcode code = b1 & OPCODE_MASK;
        BOOL isMasked = b2 & MASKED_MASK;
        if(!isMasked){
            NSError *error = [NSError errorWithDomain:@"Websocket" code:-1 userInfo:@{@"error": @"client data is not masked"}];
            [self onError:error];
            return NO;
        }
        NSUInteger payloadLength = b2 & PAYLOAD_LEN_MASK;
        switch (code) {
            case OPCODE_CLOSE:
                if(!_closed){
                    NSLog(@"client actively closed websocket");
                    [self sendClose];
                }
                return NO;
            case OPCODE_PING:
            case OPCODE_PONG:
            case OPCODE_TEXT:
            case OPCODE_BINARY:
                break;
            default:
                [self onError:[NSError errorWithDomain:@"Websocket" code:-1 userInfo:@{@"error": [NSString stringWithFormat:@"unexpected opcode: %lu", code]}]];
                return NO;
        }
        err = [self handleMessageWithCode:code length:payloadLength];
        if(err){
            [self onError:err];
            return NO;
        }
    }
    return YES;
}

-(void)onConnected{
    NSLog(@"Websocket connected");
}

-(void)onClosed{
    NSLog(@"Websocket closed");
}

-(void)onError:(NSError *)error{
    NSLog(@"Websocket error: %@", error);
}

-(void)onData:(NSData*)data{
    // nothing to do
}

-(void)onText:(NSString*)text{
    // nothing to do
}

-(void)onPing:(NSString*)msg{
    [self sendData:[msg dataUsingEncoding:NSUTF8StringEncoding] opcode:OPCODE_PONG masked:YES];
}

-(void)onPong:(NSString*)msg{
    // nothing to do
}


-(void)sendClose{
    uint16_t status = CFSwapInt16BigToHost((uint16_t)1000);
    [self sendData:[NSData dataWithBytes:&status length:sizeof(status)] opcode:OPCODE_CLOSE masked:YES];
}


-(void)close{
    _closed = YES;
    [self sendClose];
}

@end
