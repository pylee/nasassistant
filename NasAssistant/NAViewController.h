//
//  NAViewController.h
//  NasAssistant
//
//  Created by GuoTeng on 13-5-29.
//  Copyright (c) 2013年 baroqueworkshop. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncSocket.h"
#import "AsyncSocket.h"


@interface NAViewController : UIViewController <GCDAsyncSocketDelegate, AsyncSocketDelegate> {
}

@property (nonatomic, retain) GCDAsyncSocket *asyncSocket;


@end
