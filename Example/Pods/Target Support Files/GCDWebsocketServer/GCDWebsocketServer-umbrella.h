#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GCDWebsocketServer.h"
#import "GCDWebsocketServerConnection.h"
#import "GCDWebsocketServerHandler.h"
#import "GCDWebsocketServerResponse.h"

FOUNDATION_EXPORT double GCDWebsocketServerVersionNumber;
FOUNDATION_EXPORT const unsigned char GCDWebsocketServerVersionString[];

