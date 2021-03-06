//
//  LHChatVC.h
//  LHChatUI
//
//  Created by hyt on 2016/12/22.
//  Copyright © 2016年 hyt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <floo-ios/BMXRoster.h>
#import <floo-ios/BMXMessageObject.h>
#import <floo-ios/BMXGroup.h>

@protocol ChatVCDelegate <NSObject>

- (void)chatVCDidSelectReturnButton;

@end

@interface LHChatVC : UIViewController

- (instancetype)initWithRoster:(BMXRoster *)roster
                   messageType:(BMXMessageType)messageType;

- (instancetype)initWithGroupChat:(BMXGroup *)group
                      messageType:(BMXMessageType)messageType;

@property (nonatomic,weak) id<ChatVCDelegate> delegate;



@end
