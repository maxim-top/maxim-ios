//
//  ----------------------------------------------------------------------
//   File    :  GroupManageViewController.h
//   Author  : shaohui.yang shaohui@bmxlabs.com
//   Purpose :
//   Created : 2018/12/25 by shaohui.yang shaohui@bmxlabs.com
//
//  ----------------------------------------------------------------------
//
//                    Copyright (C) 2018-2019   MaxIM.Top
//
// You may obtain a copy of the licence at http://www.maxim.top/LICENCE-MAXIM.md
//
//  ----------------------------------------------------------------------
    

#import <UIKit/UIKit.h>
#import "GroupBaseController.h"

@protocol GroupManagerProtocol <NSObject>

- (void)updateGroup:(BMXGroup *)group;

@end



@interface GroupManageViewController : GroupBaseController

@property (nonatomic, strong) id<GroupManagerProtocol> delegate;

@end
