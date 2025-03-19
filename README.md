# GCDWebsocketServer

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

HTTP and Websocket can reuse the same path with no conflict.

To add a websocket handler, use `addWebsocketHandlerForPath:withProcessBlock`.

Usage:

```objectivec


-(void)SetupServer{
    GCDWebsocketServer *server = [[GCDWebsocketServer alloc] init];
    [server addWebsocketHandlerForPath:@"/" withProcessBlock:^GCDWebsocketServerHandler * _Nullable(GCDWebsocketServerConnection * _Nonnull conn) {
        return [GCDWebsocketServerHandler handlerWithConn:conn];
    }];
    [server addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
        return [GCDWebServerDataResponse responseWithText:@"ok\n"];
    }];
    NSDictionary *options = @{
        GCDWebServerOption_Port: @(9999),
    };
    NSError *error;
    [server startWithOptions:options error:&error];
    if(error){
        NSLog(@"start server failed for: %@", error);
    }
}
```

## Installation

GCDWebsocketServer is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GCDWebsocketServer'
```

## Author

guyingzhao, 572488191@qq.com

## License

GCDWebsocketServer is available under the MIT license. See the LICENSE file for more info.
