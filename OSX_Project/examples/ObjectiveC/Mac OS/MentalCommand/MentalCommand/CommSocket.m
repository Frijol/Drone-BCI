//
//  DomainSocket.m
//  MentalCommand
//
//  Created by Jon McKay on 12/14/15.
//  Copyright © 2015 emotiv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommSocket.h"

#import <sys/un.h>
#import <sys/socket.h>

#pragma mark Socket Superclass:

@interface CommSocket ()
@property (readwrite, nonatomic) CFSocketRef sockRef;
@property (readwrite, strong, nonatomic) NSURL *sockURL;
@end

@implementation CommSocket
@synthesize sockConnected;
@synthesize sockRef, sockURL;

- (BOOL) isSockRefValid {
    if ( self.sockRef == nil ) return NO;
    return (BOOL)CFSocketIsValid( self.sockRef );
}

- (NSData *) sockAddress {
    
    struct sockaddr_un address;
    address.sun_family = AF_UNIX;
    strcpy( address.sun_path, [[self.sockURL path] fileSystemRepresentation] );
    address.sun_len = SUN_LEN( &address );
    return [NSData dataWithBytes:&address length:sizeof(struct sockaddr_un)];
}

- (NSString *) sockLastError {
    return [NSString stringWithFormat:@"%s (%d)", strerror( errno ), errno ];
}

@end

#pragma mark - Socket: Server
#pragma mark -

@interface CommSocketServer ()
@property (readonly, nonatomic) BOOL startServerCleanup;
@property (readwrite, nonatomic) CommSocketServerStatus sockStatus;
@property (readwrite,  strong, nonatomic) NSSet *sockClients;
static void SocketServerCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
@end

#pragma mark - Server Implementation:

@implementation CommSocketServer

@synthesize delegate;
@synthesize sockStatus;
@synthesize sockClients;

#pragma mark - Helper Methods:

- (BOOL) socketServerCreate {
    
    if ( self.sockRef != nil ) return NO;
    CFSocketNativeHandle sock = socket( AF_UNIX, SOCK_STREAM, 0 );
    CFSocketContext context = { 0, (__bridge void *)self, nil, nil, nil };
    CFSocketRef refSock = CFSocketCreateWithNative( nil, sock, kCFSocketAcceptCallBack, SocketServerCallback, &context );
    
    if ( refSock == nil ) return NO;
    
    int opt = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, (void *)&opt, sizeof(opt));
    setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, (void *)&opt, sizeof(opt));
    
    self.sockRef = refSock;
    CFRelease( refSock );
    
    return YES;
}

- (BOOL) socketServerBind {
    if ( self.sockRef == nil ) return NO;
    unlink( [[self.sockURL path] fileSystemRepresentation] );
    if ( CFSocketSetAddress(self.sockRef, (__bridge CFDataRef)self.sockAddress) != kCFSocketSuccess ) return NO;
    return YES;
}

#pragma mark - Connected Clients:

- (void) disconnectClients {
    
    
    for ( CommSocketClient *client in self.sockClients )
        [client stopClient];
    
    self.sockClients = [NSSet set];
}

- (void) disconnectClient:(CommSocketClient *)client {
    
    @synchronized( self ) {
        NSMutableSet *clients = [NSMutableSet setWithSet:self.sockClients];
        
        if ( [clients containsObject:client] ) {
            
            if ( client.isSockRefValid ) [client stopClient];
            [clients removeObject:client];
            self.sockClients = clients;
        } }
}

- (void) addConnectedClient:(CFSocketNativeHandle)handle {
    
    @synchronized( self ) {
        CommSocketClient *client = [CommSocketClient initWithSocket:handle];
        client.delegate = self;
        NSMutableSet *clients = [NSMutableSet setWithSet:self.sockClients];
        
        if ( client.isSockConnected ) {
            [clients addObject:client];
            self.sockClients = clients;
        } }
}

#pragma mark - Connected Client Protocols:

- (void) handleSocketClientDisconnect:(CommSocketClient *)client {
    
    [self disconnectClient:client];
}

- (void) handleSocketClientMsgURL:(NSURL *)aURL client:(CommSocketClient *)client {
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketServerMsgURL:server:fromClient:)] )
        [self.delegate handleSocketServerMsgURL:aURL fromClient:client];
}

- (void) handleSocketClientMsgString:(NSString *)aString client:(CommSocketClient *)client {
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketServerMsgString:fromClient:)] )
        [self.delegate handleSocketServerMsgString:aString fromClient:client];
}

- (void) handleSocketClientMsgNumber:(NSNumber *)aNumber client:(CommSocketClient *)client {
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketServerMsgNumber:fromClient:)] )
        [self.delegate handleSocketClientMsgNumber:aNumber client:client];
}

- (void) handleSocketClientMsgArray:(NSArray *)aArray client:(CommSocketClient *)client {
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketServerMsgArray:fromClient:)] )
        [self.delegate handleSocketServerMsgArray:aArray fromClient:client];
}

- (void) handleSocketClientMsgDict:(NSDictionary *)aDict client:(CommSocketClient *)client {
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketServerMsgDict:fromClient:)] )
        [self.delegate handleSocketServerMsgDict:aDict fromClient:client];
}

#pragma mark - Connected Client Messaging:

- (void) messageClientsURL:(NSURL *)aURL {
    for ( CommSocketClient *client in self.sockClients)
        [client messageURL:aURL];
}

- (void) messageClientsString:(NSString *)aString {
    for ( CommSocketClient *client in self.sockClients)
        [client messageString:aString];
}

- (void) messageClientsNumber:(NSNumber *)aNumber {
    for ( CommSocketClient *client in self.sockClients)
        [client messageNumber:aNumber];
}

- (void) messageClientsArray:(NSArray *)aArray {
    for ( CommSocketClient *client in self.sockClients)
        [client messageArray:aArray];
}

- (void) messageClientsDict:(NSDictionary *)aDict {
    for ( CommSocketClient *client in self.sockClients)
        [client messageDict:aDict];
}

- (void) messageClientsData:(NSData *)aData {
    for ( CommSocketClient *client in self.sockClients)
        [client messageData:aData];
}

#pragma mark - Start / Stop Server:

- (BOOL) startServerCleanup { [self stopServer]; return NO; }

- (BOOL) startServer {
    
    if ( self.sockStatus == CommSocketServerStatusRunning ) return YES;
    self.sockStatus = CommSocketServerStatusStarting;
    
    if ( ![self socketServerCreate] ) return self.startServerCleanup;
    if ( ![self socketServerBind]   ) return self.startServerCleanup;
    
    CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource( kCFAllocatorDefault, self.sockRef, 0 );
    CFRunLoopAddSource( CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes );
    CFRelease( sourceRef );
    
    self.sockStatus = CommSocketServerStatusRunning;
    return YES;
}

- (BOOL) stopServer {
    
    self.sockStatus = CommSocketServerStatusStopping;
    
    [self disconnectClients];
    
    if ( self.sockRef != nil ) {
        
        CFSocketInvalidate(self.sockRef);
        self.sockRef = nil;
    }
    
    unlink( [[self.sockURL path] fileSystemRepresentation] );
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketServerStopped:)] )
        [self.delegate handleSocketServerStopped:self];
    
    self.sockStatus = CommSocketServerStatusStopped;
    return YES;
}

#pragma mark - Server Validation:

- (BOOL) isSockConnected {
    
    if ( self.sockStatus == CommSocketServerStatusRunning )
        return self.isSockRefValid;
    
    return NO;
}

#pragma mark - Initialization:

+ (id) initAndStartServer:(NSURL *)socketURL {
    
    CommSocketServer *server = [[CommSocketServer alloc] initWithSocketURL:socketURL];
    bool ret = [server startServer];
    if (ret != YES) {
        NSLog(@"Issues creating server...");
    }
    else {
        NSLog(@"Created server successfully!");
    }
    return server;
}

- (id) initWithSocketURL:(NSURL *)socketURL {
    
    if ( (self = [super init]) ) {
        
        self.sockURL     = socketURL;
        self.sockStatus  = CommSocketServerStatusStopped;
        self.sockClients = [NSSet set];
        
    } return self;
}

- (void) dealloc { [self stopServer]; }

#pragma mark - Server Callback:

static void SocketServerCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    
    CommSocketServer *server = (__bridge CommSocketServer *)info;
    
    if ( kCFSocketAcceptCallBack == type ) {
        CFSocketNativeHandle handle = *(CFSocketNativeHandle *)data;
        [server addConnectedClient:handle];
    }
}

@end
#pragma mark - Socket: Client
#pragma mark -

@interface CommSocketClient ()
@property (readonly, nonatomic) BOOL startClientCleanup;
@property (readwrite, nonatomic) CommSocketClientStatus sockStatus;
@property (readwrite, nonatomic) CFRunLoopSourceRef sockRLSourceRef;
static void SocketClientCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
@end

#pragma mark - Client Implementation:

@implementation CommSocketClient

static NSTimeInterval const kCommSocketClientTimeout = 5.0;

@synthesize delegate;
@synthesize sockStatus;
@synthesize sockRLSourceRef;

#pragma mark - Helper Methods:

- (BOOL) socketClientCreate:(CFSocketNativeHandle)sock {
    
    if ( self.sockRef != nil ) return NO;
    CFSocketContext context = { 0, (__bridge void *)self, nil, nil, nil };
    CFSocketCallBackType types = kCFSocketDataCallBack;
    CFSocketRef refSock = CFSocketCreateWithNative( nil, sock, types, SocketClientCallback, &context );
    
    if ( refSock == nil ) return NO;
    
    int opt = 1;
    setsockopt(sock, SOL_SOCKET, SO_NOSIGPIPE, (void *)&opt, sizeof(opt));
    
    self.sockRef = refSock;
    CFRelease( refSock );
    
    return YES;
}

- (BOOL) socketClientBind {
    if ( self.sockRef == nil ) return NO;
    if ( CFSocketConnectToAddress(self.sockRef,
                                  (__bridge CFDataRef)self.sockAddress,
                                  (CFTimeInterval)kCommSocketClientTimeout) != kCFSocketSuccess ) return NO;
    return YES;
}

#pragma mark - Client Messaging:

- (void) messageReceived:(NSData *)data {
    
    id msg = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if ( [msg isKindOfClass:[NSURL class]] ) {
        
        if ( [self.delegate respondsToSelector:@selector(handleSocketClientMsgURL:client:)] )
            [self.delegate handleSocketClientMsgURL:(NSURL *)msg client:self];
    }
    
    else if ( [msg isKindOfClass:[NSString class]] ) {
        
        if ( [self.delegate respondsToSelector:@selector(handleSocketClientMsgString:client:)] )
            [self.delegate handleSocketClientMsgString:(NSString *)msg client:self];
    }
    
    else if ( [msg isKindOfClass:[NSNumber class]] ) {
        
        if ( [self.delegate respondsToSelector:@selector(handleSocketClientMsgNumber:client:)] )
            [self.delegate handleSocketClientMsgNumber:(NSNumber *)msg client:self];
    }
    
    else if ( [msg isKindOfClass:[NSArray class]] ) {
        
        if ( [self.delegate respondsToSelector:@selector(handleSocketClientMsgArray:client:)] )
            [self.delegate handleSocketClientMsgArray:(NSArray *)msg client:self];
    }
    
    else if ( [msg isKindOfClass:[NSDictionary class]] ) {
        
        if ( [self.delegate respondsToSelector:@selector(handleSocketClientMsgDict:client:)] )
            [self.delegate handleSocketClientMsgDict:(NSDictionary *)msg client:self];
    }
}

- (BOOL) messageData:(NSData *)data {
    
    if ( self.isSockConnected ) {
        
        if ( kCFSocketSuccess == CFSocketSendData(self.sockRef,
                                                  nil,
                                                  (__bridge CFDataRef)data,
                                                  kCommSocketClientTimeout) )
            return YES;
        
    } return NO;
}

- (BOOL) messageURL:(NSURL *)aURL          { return [self messageData:[NSKeyedArchiver archivedDataWithRootObject:aURL]];    }
- (BOOL) messageString:(NSString *)aString { return [self messageData:[aString dataUsingEncoding:NSUTF8StringEncoding]]; }
- (BOOL) messageNumber:(NSNumber *)aNumber { return [self messageData:[NSKeyedArchiver archivedDataWithRootObject:aNumber]]; }
- (BOOL) messageArray:(NSArray *)aArray    { return [self messageData:[NSKeyedArchiver archivedDataWithRootObject:aArray]];  }
- (BOOL) messageDict:(NSDictionary *)aDict { return [self messageData:[NSKeyedArchiver archivedDataWithRootObject:aDict]];   }

#pragma mark - Start / Stop Client:

- (BOOL) startClientCleanup { [self stopClient]; return NO; }

- (BOOL) startClient {
    
    if ( self.sockStatus == CommSocketClientStatusLinked ) return YES;
    self.sockStatus = CommSocketClientStatusLinking;
    
    CFSocketNativeHandle sock = socket( AF_UNIX, SOCK_STREAM, 0 );
    if ( ![self socketClientCreate:sock] ) return self.startClientCleanup;
    if ( ![self socketClientBind]        ) return self.startClientCleanup;
    
    CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource( kCFAllocatorDefault, self.sockRef, 0 );
    CFRunLoopAddSource( CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes );
    
    self.sockRLSourceRef = sourceRef;
    CFRelease( sourceRef );
    
    self.sockStatus = CommSocketClientStatusLinked;
    return YES;
}

- (BOOL) stopClient {
    
    self.sockStatus = CommSocketClientStatusDisconnecting;
    
    if ( self.sockRef != nil ) {
        
        if ( self.sockRLSourceRef != nil ) {
            
            CFRunLoopSourceInvalidate( self.sockRLSourceRef );
            self.sockRLSourceRef = nil;
        }
        
        CFSocketInvalidate(self.sockRef);
        self.sockRef = nil;
    }
    
    if ( [self.delegate respondsToSelector:@selector(handleSocketClientDisconnect:)] )
        [self.delegate handleSocketClientDisconnect:self];
    
    self.sockStatus = CommSocketClientStatusDisconnected;
    
    return YES;
}

#pragma mark - Client Validation:

- (BOOL) isSockConnected {
    
    if ( self.sockStatus == CommSocketClientStatusLinked )
        return self.isSockRefValid;
    
    return NO;
}

#pragma mark - Initialization:

+ (id) initAndStartClient:(NSURL *)socketURL {
    
    CommSocketClient *client = [[CommSocketClient alloc] initWithSocketURL:socketURL];
    [client startClient];
    return client;
}

+ (id) initWithSocket:(CFSocketNativeHandle)handle {
    
    CommSocketClient *client = [[CommSocketClient alloc] initWithSocket:handle];
    return client;
}

- (id) initWithSocketURL:(NSURL *)socketURL {
    
    if ( (self = [super init]) ) {
        
        self.sockURL    = socketURL;
        self.sockStatus = CommSocketClientStatusDisconnected;
        
    } return self;
}

- (id) initWithSocket:(CFSocketNativeHandle)handle {
    
    if ( (self = [super init]) ) {
        
        self.sockStatus = CommSocketClientStatusLinking;
        
        if ( ![self socketClientCreate:handle] ) [self startClientCleanup];
        
        else {
            
            CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource( kCFAllocatorDefault, self.sockRef, 0 );
            CFRunLoopAddSource( CFRunLoopGetCurrent(), sourceRef, kCFRunLoopCommonModes );
            
            self.sockRLSourceRef = sourceRef;
            CFRelease( sourceRef );
            
            self.sockStatus = CommSocketClientStatusLinked;
        }
        
    } return self;
}

- (void) dealloc { [self stopClient]; }

#pragma mark - Client Callback:

static void SocketClientCallback (CFSocketRef sock, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    
    CommSocketClient *client = (__bridge CommSocketClient *)info;
    
    if ( kCFSocketDataCallBack == type ) {
        
        NSData *objData = (__bridge NSData *)data;
        
        if ( [objData length] == 0 )
            [client stopClient];
        
        else
            [client messageReceived:objData];
    }
}

@end
