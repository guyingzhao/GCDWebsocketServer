//
//  GCDWEBSOCKETSERVERHandler.m
//  GCDWebsocketServer_Example
//
//  Created by guying on 2025/3/22.
//  Copyright © 2025 guyingzhao. All rights reserved.
//

#import "GCDWEBSOCKETSERVERHandler.h"

@implementation GCDWEBSOCKETSERVERHandler

-(void)onData:(NSData *)data{
    [self sendData:data opcode:OPCODE_BINARY];
}

-(void)onText:(NSString *)text{
    [self sendText:text];
}

@end
