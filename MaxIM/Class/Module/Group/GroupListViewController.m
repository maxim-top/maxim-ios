

//
//  ----------------------------------------------------------------------
//   File    :  GroupListViewController.m
//   Author  : HYT yutong@bmxlabs.com
//   Purpose :
//   Created : 2018/12/23 by HYT yutong@bmxlabs.com
//
//  ----------------------------------------------------------------------
//
//                    Copyright (C) 2018-2019   MaxIM.Top
//
// You may obtain a copy of the licence at http://www.maxim.top/LICENCE-MAXIM.md
//
//  ----------------------------------------------------------------------
    

#import "GroupListViewController.h"
#import "ImageTitleBasicTableViewCell.h"
#import <floo-ios/BMXClient.h>
#import "LHChatVC.h"

#import "GroupCreateViewController.h"
#import "GroupInviteViewController.h"
#import "GroupApplyViewController.h"


@interface GroupListViewController ()<UITableViewDelegate, UITableViewDataSource, BMXGroupManager>

@property (nonatomic, strong) UITableView *tableview;

@property (nonatomic, strong) NSArray *groupArray;

@end

@implementation GroupListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self getGroupList];
    [self setUpNavItem];
    [self tableView];
    [self actionArray];
    [self setNotifications];
}

#pragma mark - Group Manager
// 获取群list
- (void)getGroupList {
    [HQCustomToast showWating];
    [[[BMXClient sharedClient] groupService] getGroupListForceRefresh:NO completion:^(NSArray *groupList, BMXError *error) {
//        MAXLog(@"%ld", groupList.count);
        [HQCustomToast hideWating];

        if (!error) {
            
            NSMutableArray *groupNormalArray = [NSMutableArray array];
            for (BMXGroup *group in groupList) {
//                MAXLog(@"%@", group.name);
//                MAXLog(@"%d", group.groupStatus);
//                MAXLog(@"%d", group.isMember);

                if (group.groupStatus != BMXGroupDestroyed && group.roleType == BMXGroupMemberRoleTypeMember) {
                    [groupNormalArray addObject:group];
                } else {
//                    MAXLog(@"%lld", group.groupId);
                }
            }
            self.groupArray = groupNormalArray;
            [self.tableView reloadData];
        }
    }];
}

// 销毁群
- (void)destroyGroupWithGroup:(BMXGroup *)group {
    [[[BMXClient sharedClient] groupService] destroyGroup:group completion:^(BMXError *error) {
        if (!error) {
            MAXLog(@"销毁群");
            [self onGrouplistChange];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.actionArray.count;
    } else {
        return  self.groupArray.count ? self.groupArray.count : 0;
    }
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ImageTitleBasicTableViewCell *cell = [ImageTitleBasicTableViewCell ImageTitleBasicTableViewCellWith:tableView];
    if (indexPath.section == 0) {
        NSString *titleStr = [NSString stringWithFormat:@"%@", self.actionArray[indexPath.row]];
        [cell refreshByTitle:titleStr];
        if ([titleStr isEqualToString:@"群申请列表"] || [titleStr isEqualToString: @"群聊系统消息"]) {
            cell.avatarImg.image = [UIImage imageNamed: [NSString stringWithFormat:@"group_application"]];
        }
    } else {
        MAXLog(@"%ld", self.groupArray.count);
        BMXGroup *group = self.groupArray[indexPath.row];
        [cell refreshByGroup:group];
        MAXLog(@"%@", group);
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            GroupCreateViewController* ctrl = [[GroupCreateViewController alloc] init];
            [ctrl hidesBottomBarWhenPushed];
            [self.navigationController pushViewController:ctrl animated:YES];
        } else if(indexPath.row == 1) {
            GroupApplyViewController *vc = [[GroupApplyViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            GroupInviteViewController *VC = [[GroupInviteViewController alloc] init];
            [self.navigationController pushViewController:VC animated:YES];
        }
        
    } else {
        BMXGroup *group = self.groupArray[indexPath.row];

        LHChatVC *vc = [[LHChatVC alloc] initWithGroupChat:group messageType:BMXMessageTypeGroup];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSArray *)actionArray {
    return @[@"新建群聊", @"群申请列表", @"群聊系统消息"];
}

- (UITableView *)tableView {
    if (!_tableview) {
        _tableview = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableview.delegate = self;
        _tableview.dataSource = self;
        [_tableview registerClass:[ImageTitleBasicTableViewCell class] forCellReuseIdentifier:@"ImageTitleBasicTableViewCell"];
        [self.view addSubview:_tableview];
    }
    return _tableview;
}

- (NSArray *)rosterArray {
    if (!_groupArray) {
        _groupArray = [NSArray array];
    }
    return _groupArray;
}

- (void)setUpNavItem{
    self.navigationController.navigationBar.barTintColor = BMXColorNavBar;
    self.navigationItem.title = @"群组";
}

- (NSArray *)groupArray {
    if (_groupArray == nil) {
        _groupArray = [NSArray array];
    }
    return _groupArray;
}

#pragma mark == delegate of create group
- (void) setNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGrouplistChange) name:@"KGroupListModified" object:nil];
}

-(void) onGrouplistChange
{
    [self getGroupList];
}
@end
