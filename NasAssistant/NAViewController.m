//
//  NAViewController.m
//  NasAssistant
//
//  Created by GuoTeng on 13-5-29.
//  Copyright (c) 2013年 baroqueworkshop. All rights reserved.
//

#import "NAViewController.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/ioctl.h>
#include <netdb.h>
#include <ifaddrs.h>

#import "DDLog.h"
#import "DDTTYLogger.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@interface NAViewController ()

@end

@implementation NAViewController

- (void)viewDidLoad
{
    DDLogInfo(@"%@", THIS_METHOD);
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    for (int i = 1; i <= 255; i++) {
        NSString *ip = [NSString stringWithFormat:@"172.18.56.%d", i];
        if ([self checkPort:ip onPort:445] && [self checkPort:ip onPort:139]) {
            DDLogInfo(@"%@ should open smb service.", ip);
            [self getHostNameByAddr:ip];
        }
    }
}

- (NSString *)getHostNameByAddr:(NSString *)ip {
    struct addrinfo hints;
    struct addrinfo *result, *result_pointer;
    int ret;
    char hostname[128] = "";
    char service[128] = "";
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_CANONNAME | AI_NUMERICHOST;
    hints.ai_protocol = 0;
    
    ret = getaddrinfo([ip cStringUsingEncoding:NSUTF8StringEncoding], NULL, &hints, &result);
    
    if (ret != 0) {
        
    }
    
    for (result_pointer = result; result_pointer != NULL; result_pointer = result_pointer->ai_next) {
        memset(hostname, 0, 128);
        ret = getnameinfo((struct sockaddr*)result_pointer->ai_addr, result_pointer->ai_addrlen, hostname, sizeof(hostname), service, sizeof(service), NI_NAMEREQD);
        if (ret != 0) {
            DDLogError(@"error in getnameinfo: %s", gai_strerror(ret));
        } else {
            DDLogInfo(@"hostname:%s", hostname);
        }
    }
    freeaddrinfo(result);
    
    return [NSString stringWithFormat:@"%s", hostname];
}

- (BOOL)checkPort:(NSString *)ip onPort:(int)port {
    DDLogInfo(@"%@,ip:%@, port:%d", THIS_METHOD, ip, port);
    
    struct sockaddr_in server;
    int scanport = port;
    int sockfd;
    
    fd_set rset;
    fd_set wset;
    struct servent *sp;
    
    if (-1 == (sockfd = socket(AF_INET, SOCK_STREAM, 0))) {
        DDLogError(@"can not create socket.");
        return NO;
    }
    
    memset(&server, 0, sizeof(struct sockaddr_in));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr([ip cStringUsingEncoding:NSUTF8StringEncoding]);
    server.sin_port = htons(scanport);
    
    int flag = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flag | O_NONBLOCK);
    struct timeval tm;
    tm.tv_sec = 0;
    tm.tv_usec = 2000;
    
    // connect 为非阻塞，连接不成功返回-1
    if (!connect(sockfd, (struct sockaddr*)&server, sizeof(struct sockaddr))) {
        sp = getservbyport(htons(scanport), "tcp");
        
        DDLogInfo(@"tcp port %d open:%s \n", scanport, sp->s_name);
    } else {
        FD_ZERO(&rset);
        FD_ZERO(&wset);
        FD_SET(sockfd, &rset);
        FD_SET(sockfd, &wset);
        int error;
        socklen_t len = sizeof(error);
        int errVal = select(sockfd + 1, &rset, &wset, NULL, &tm);
        if ( errVal > 0) {
            getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len);
            if (error == 0) {
                DDLogInfo(@"%@ Port %d is opened.",ip, scanport);
                return YES;
            } else {
                //printf("%s Port 445 is not open, error:%d \n",[ip cStringUsingEncoding:NSUTF8StringEncoding],  error);
            }
        } else {
            //printf("%s Port 445 is not open \n", [ip cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        
        close(sockfd);
    }
    return NO;
}


@end
