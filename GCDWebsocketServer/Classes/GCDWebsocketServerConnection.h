//
//  GCDWebsocketServerConnection.h
//  GCDWebsocketServer
//
//  Created by guying on 2025/3/15.
//

#import <Foundation/Foundation.h>
#import <GCDWebServer/GCDWebServerConnection.h>

NS_ASSUME_NONNULL_BEGIN


@interface GCDWebsocketServerConnection : GCDWebServerConnection
- (bool)open;
- (nullable GCDWebServerResponse*)preflightRequest:(GCDWebServerRequest*)request;
- (NSError*)readBytes:(NSMutableData*)data withLength:(size_t)length;
- (NSError*)sendBytes:(NSData*)bytes;


@end


NS_ASSUME_NONNULL_END
