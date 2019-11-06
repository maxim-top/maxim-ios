//
//  ----------------------------------------------------------------------
//   File    :  ProfileTableViewCell.h
//   Author  : HYT yutong@bmxlabs.com
//   Purpose :
//   Created : 2018/12/28 by HYT yutong@bmxlabs.com
//
//  ----------------------------------------------------------------------
//
//                    Copyright (C) 2018-2019   MaxIM.Top
//
// You may obtain a copy of the licence at http://www.maxim.top/LICENCE-MAXIM.md
//
//  ----------------------------------------------------------------------
    

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileTableViewCell : UITableViewCell

+ (instancetype)cellWithTableView:(UITableView *)tableview;

@property (nonatomic, strong) UIImageView *avatarimageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;



@end

NS_ASSUME_NONNULL_END
