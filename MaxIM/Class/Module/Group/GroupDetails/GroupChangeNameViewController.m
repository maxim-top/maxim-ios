//
//  ----------------------------------------------------------------------
//   File    :  GroupChangeNameViewController.m
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
    

#import "GroupChangeNameViewController.h"
#import <floo-ios/BMXClient.h>
#import "UIViewController+CustomNavigationBar.h"

@interface GroupChangeNameViewController ()
{
    UITextField* _textField;
}

@end

@implementation GroupChangeNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    [self setUpNavItem];
    [self initViews];
}


-(void) initViews {
    _textField = [[UITextField alloc] initWithFrame:CGRectMake(25, 25 + NavHeight, MAXScreenW-50, 40)];
    [self.view addSubview:_textField];
    _textField.text = self.group.name;
    _textField.layer.borderWidth = 0.5;
    _textField.layer.masksToBounds = YES;
    _textField.layer.cornerRadius = 3.0f;
    _textField.layer.borderColor = [UIColor colorWithRed:223/255.0 green:223/255.0 blue:223/255.0 alpha:1/1.0].CGColor;
    _textField.leftViewMode = UITextFieldViewModeAlways;
    _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 30)];
    [_textField becomeFirstResponder];
}

-(void) touchedRightBar {
    [[[BMXClient sharedClient] groupService] setGroupName:self.group name:_textField.text completion:^(BMXGroup *group, BMXError *error) {
        if (!error) {
            [HQCustomToast showDialog:@"设置成功"];
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [HQCustomToast showDialog:[NSString stringWithFormat:@"%@", error.errorMessage]];
        }
    }];
}

- (void)setUpNavItem {
    [self setNavigationBarTitle: @"修改群名称" navLeftButtonIcon:@"blackback" navRightButtonTitle:@"保存"];
    [self.navRightButton addTarget:self action:@selector(touchedRightBar) forControlEvents:UIControlEventTouchUpInside];
}

@end
