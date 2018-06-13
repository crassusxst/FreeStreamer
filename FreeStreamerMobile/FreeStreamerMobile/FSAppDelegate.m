/*
 * This file is part of the FreeStreamer project,
 * (C)Copyright 2011-2018 Matias Muhonen <mmu@iki.fi> 穆马帝
 * See the file ''LICENSE'' for using the code.
 *
 * https://github.com/muhku/FreeStreamer
 */

#import "FSAppDelegate.h"

#define HOST @"172.16.13.107"
#define PORT 8999

typedef enum : NSUInteger {
    SocketOfflineByUser,
    SocketOfflineByWifiCut,  // wifi断开
    SocketOfflineByServer,   // 服务器掉线
} SocketOfflineType;

@implementation FSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self.window setRootViewController:self.navigationController];
    [self.window makeKeyAndVisible];

    [self socketConnectHost];
    return YES;
}

// 建立socket连接
-(void)socketConnectHost{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(0, 0);
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:globalQueue];
    NSError *error = nil;
    NSString *host = HOST;
    uint16_t port = PORT;
    if (![asyncSocket connectToHost:host onPort:port error:&error])
    {
        NSLog(@"%@, 链接错误", error);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)statrtTime
{

}

// 心跳连接
-(void)longConnectToSocket{
    // 根据服务器要求发送固定格式的数据，假设为指令@"longConnect"，但是一般不会是这么简单的指令
    NSString *longConnect = @"longConnect";
    NSData   *dataStream  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [asyncSocket writeData:dataStream withTimeout:1 tag:1];
}

- (void)cutOffSocket {
    [asyncSocket disconnect];
    asyncSocket.userData =  @(SocketOfflineByUser);
    NSLog(@"断开连接");
}

#pragma mark Getter
- (NSMutableData *)bufferData
{
    if (!_bufferData) {
        _bufferData = NSMutableData.new;
    }
    return _bufferData;
}

#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// socket成功连接回调
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"socket:%p didConnectToHost:%@ port:%hu", sock, host, port);
    [asyncSocket readDataWithTimeout:-1 tag:99];
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    NSLog(@"socketDidSecure:%p", sock);
//    self.viewController.label.text = @"Connected + Secure";

    NSString *requestStr = [NSString stringWithFormat:@"GET / HTTP/1.1\r\nHost: %@\r\n\r\n", HOST];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];

    [sock writeData:requestData withTimeout:-1 tag:0];
    [sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"socket:%p didWriteDataWithTag:%ld", sock, tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"socket:%p didReadData:withTag:%ld", sock, tag);

    NSString *httpResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSLog(@"HTTP Response:\n%@", httpResponse);

}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"socketDidDisconnect:%p withError: %@", sock, err);
    if (err.code == 57) {
        asyncSocket.userData = @(SocketOfflineByWifiCut); // wifi断开
    }
    else {
        asyncSocket.userData =  @(SocketOfflineByServer);  // 服务器掉线
    }
}

- (void)resetBackground
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.window.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"player-bg-image.jpg"]];
    } else {
        self.window.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"player-bg-image-pad.jpg"]];
    }
}

@end
