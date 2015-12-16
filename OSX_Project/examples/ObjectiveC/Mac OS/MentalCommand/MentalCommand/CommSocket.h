typedef enum _CommSocketServerStatus {
    
    CommSocketServerStatusUnknown       = 0,
    CommSocketServerStatusRunning       = 1,
    CommSocketServerStatusStopped       = 2,
    CommSocketServerStatusStarting      = 3,
    CommSocketServerStatusStopping      = 4
    
} CommSocketServerStatus;

typedef enum _CommSocketClientStatus {
    
    CommSocketClientStatusUnknown       = 0,
    CommSocketClientStatusLinked        = 1,
    CommSocketClientStatusDisconnected  = 2,
    CommSocketClientStatusLinking       = 3,
    CommSocketClientStatusDisconnecting = 4
    
} CommSocketClientStatus;

@class CommSocketServer, CommSocketClient;

@protocol CommSocketServerDelegate <NSObject>
@optional
- (void) handleSocketServerStopped:(CommSocketServer *)server;
- (void) handleSocketServerMsgURL:(NSURL *)aURL          fromClient:(CommSocketClient *)client;
- (void) handleSocketServerMsgString:(NSString *)aString fromClient:(CommSocketClient *)client;
- (void) handleSocketServerMsgNumber:(NSNumber *)aNumber fromClient:(CommSocketClient *)client;
- (void) handleSocketServerMsgArray:(NSArray *)aArray    fromClient:(CommSocketClient *)client;
- (void) handleSocketServerMsgDict:(NSDictionary *)aDict fromClient:(CommSocketClient *)client;
@end

@protocol CommSocketClientDelegate <NSObject>
@optional
- (void) handleSocketClientDisconnect:(CommSocketClient *)client;
- (void) handleSocketClientMsgURL:(NSURL *)aURL          client:(CommSocketClient *)client;
- (void) handleSocketClientMsgString:(NSString *)aString client:(CommSocketClient *)client;
- (void) handleSocketClientMsgNumber:(NSNumber *)aNumber client:(CommSocketClient *)client;
- (void) handleSocketClientMsgArray:(NSArray *)aArray    client:(CommSocketClient *)client;
- (void) handleSocketClientMsgDict:(NSDictionary *)aDict client:(CommSocketClient *)client;
@end

@interface CommSocket : NSObject
@property (readonly, nonatomic, getter=isSockRefValid) BOOL sockRefValid;
@property (readonly, nonatomic, getter=isSockConnected) BOOL sockConnected;
@property (readonly, nonatomic) CFSocketRef sockRef;
@property (readonly, strong, nonatomic) NSURL    *sockURL;
@property (readonly, strong, nonatomic) NSData   *sockAddress;
@property (readonly, strong, nonatomic) NSString *sockLastError;
@end

@interface CommSocketServer : CommSocket <CommSocketClientDelegate> { id <CommSocketServerDelegate> delegate; }
@property (readwrite, strong, nonatomic) id delegate;
@property (readonly,  strong, nonatomic) NSSet *sockClients;
@property (readonly, nonatomic) CommSocketServerStatus sockStatus;
@property (readonly, nonatomic) BOOL startServer;
@property (readonly, nonatomic) BOOL stopServer;
- (id) initWithSocketURL:(NSURL *)socketURL;
+ (id) initAndStartServer:(NSURL *)socketURL;
- (void) addConnectedClient:(CFSocketNativeHandle)handle;

- (void) messageClientsURL:(NSURL *)aURL;
- (void) messageClientsString:(NSString *)aString;
- (void) messageClientsNumber:(NSNumber *)aNumber;
- (void) messageClientsArray:(NSArray *)aArray;
- (void) messageClientsDict:(NSDictionary *)aDict;
- (void) messageClientsData:(NSData *)aData;

@end

@interface CommSocketClient : CommSocket { id <CommSocketClientDelegate> delegate; }
@property (readwrite, strong, nonatomic) id delegate;
@property (readonly, nonatomic) CommSocketClientStatus sockStatus;
@property (readonly, nonatomic) CFRunLoopSourceRef sockRLSourceRef;
@property (readonly, nonatomic) BOOL startClient;
@property (readonly, nonatomic) BOOL stopClient;
- (id) initWithSocketURL:(NSURL *)socketURL;
- (id) initWithSocket:(CFSocketNativeHandle)handle;
+ (id) initAndStartClient:(NSURL *)socketURL;
+ (id) initWithSocket:(CFSocketNativeHandle)handle;

- (void) messageReceived:(NSData *)data;
- (BOOL) messageURL:(NSURL *)aURL;
- (BOOL) messageString:(NSString *)aString;
- (BOOL) messageNumber:(NSNumber *)aNumber;
- (BOOL) messageArray:(NSArray *)aArray;
- (BOOL) messageDict:(NSDictionary *)aDict;
- (BOOL) messageData:(NSData *)aData;

@end