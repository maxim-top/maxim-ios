//
//  ContactListViewController.m
//  MaxIM
//
//  Created by hyt on 2018/11/17.
//  Copyright © 2018年 hyt. All rights reserved.
//

#import "ContactListViewController.h"
#import "RosterSearchViewController.h"
#import "RosterDetailViewController.h"
#import "ImageTitleBasicTableViewCell.h"
#import "LHChatVC.h"
#import "GroupListViewController.h"
#import "UIViewController+CustomNavigationBar.h"
#import <floo-ios/BMXClient.h>
#import "GroupListTableViewAdapter.h"
#import <floo-ios/BMXGroup.h>
#import "GroupCreateViewController.h"
#import "GroupApplyViewController.h"
#import "GroupInviteViewController.h"
#import "SupportStaffApi.h"
#import "MenuView.h"
#import "UIControl+Category.h"
#import "ScanViewController.h"
#import "GroupCreateViewController.h"
#import "MenuViewManager.h"
#import "MaxEmptyTipView.h"
#import "AppIDManager.h"
#import "ZoomMeetingsApi.h"
#import <MobileRTC/MobileRTC.h>
#import "IMAcountInfoStorage.h"
#import "IMAcount.h"

@interface ContactListViewController ()<UITableViewDelegate,
                                        UITableViewDataSource,
                                        BMXRosterServiceProtocol,
                                        MenuViewDeleagte,
                                        MobileRTCMeetingServiceDelegate>

@property (nonatomic, strong) UITableView *rosterListTableView;
@property (nonatomic, strong) UITableView *groupListTableView;
@property (nonatomic, strong) UITableView *supportListTableView;
@property (nonatomic, strong) UITableView *meetingsTableView;

@property (nonatomic, strong) NSArray<BMXGroup *> *groupArray;
@property (nonatomic, strong) NSArray *groupTableviewCellArray;

@property (nonatomic, strong) NSArray *rosterArray;
@property (nonatomic, strong) NSArray *rosterIdArray;
@property (nonatomic, strong) NSArray *actionArray;
@property (nonatomic, strong) NSArray *keyArray;

@property (nonatomic,assign) NSInteger tag;
@property (nonatomic, strong) UIView *selectView;
@property (nonatomic, strong) UIView *navSepLine;

@property (nonatomic, strong) NSArray *supportArray;
@property (nonatomic, strong) NSArray *meetingArray;
@property (nonatomic, strong) MenuViewManager *menuViewManager;

@property (nonatomic, strong) MaxEmptyTipView *tipView;

@end

@implementation ContactListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavItem];
    [self selectView];
    [self rosterListTableView];
    [self getAllRoster];
    [self actionArray];
    [self.rosterListTableView reloadData];
    
    
    [self configSupportData];
    [self getMeettings];
    
    [[[BMXClient sharedClient] rosterService] addRosterListener:self];
    
    [self setNotifications];

}

- (void)hideMenu {
    [self.menuViewManager hide];
}

- (void)configSupportData {
    if ([self isShowSupportData]) {
        [self getSupportData];
    } else {
        
    }
}

- (BOOL)isShowSupportData {
    if ([[[BMXClient sharedClient] sdkConfig].appID isEqualToString:BMXAppID]) {
        return YES;
    }
    return NO;
}

- (void)getMeettings {
    ZoomMeetingsApi *api  = [[ZoomMeetingsApi alloc] init];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK ) {
            NSArray *array = [NSArray arrayWithArray:result.resultData];
            self.meetingArray = array;
            [self.meetingsTableView reloadData];
        }
    } failureBlock:^(NSError * _Nullable error) {
        [HQCustomToast showNetworkError];

    }];
}

- (void)getSupportData {
    SupportStaffApi *api  = [[SupportStaffApi alloc] init];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        MAXLog(@"aaaaaaaaa");
        if (result.isOK) {
            NSMutableArray *idArrayM = [NSMutableArray array];
            for (NSDictionary *dic in result.resultData) {
                [idArrayM addObject:[NSString stringWithFormat:@"%@", dic[@"user_id"]]];
            }
            [self getSupportListProfileWithArray:[NSArray arrayWithArray:idArrayM]];
        } else {
            MAXLog(@"bbbbbb");
        }
    } failureBlock:^(NSError * _Nullable error) {
        [HQCustomToast showNetworkError];
    }];
}

- (void)getSupportListProfileWithArray:(NSArray *)array {
    [[[BMXClient sharedClient] rosterService] searchRostersByRosterIdList:array forceRefresh:NO completion:^(NSArray<BMXRoster *> *rosterList, BMXError *error) {
        if (!error) {
            self.supportArray = rosterList;
            [self.supportListTableView reloadData];
        }
    }];
    
}

- (void)contactRefreshIfNeededToast:(BOOL)isNeed {
    [self getAllRosterWithToast:isNeed];
}

// 获取好友列表
- (void)getAllRosterWithToast:(BOOL)isNeed {
    if (isNeed == YES) {
        [HQCustomToast showWating];
    }
    [[[BMXClient sharedClient] rosterService] getRosterListforceRefresh:NO completion:^(NSArray *rostIdList, BMXError *error) {
        if (!error) {
            MAXLog(@"%ld", rostIdList.count);
            [self searchRostersByidArray:[NSArray arrayWithArray:rostIdList]];
        }
    }];
}

#pragma mark - Manager
// 同意好友申请
- (void)acceptApplication:(NSInteger)rosterId {
    [[[BMXClient sharedClient] rosterService] acceptRosterById:rosterId withCompletion:^(BMXError *error) {
        MAXLog(@"%@", error);
    }];
}

// 获取好友列表
- (void)getAllRoster {
    [HQCustomToast showWating];
    [[[BMXClient sharedClient] rosterService] getRosterListforceRefresh:NO completion:^(NSArray *rostIdList, BMXError *error) {
        if (!error) {
            MAXLog(@"%lu", (unsigned long)rostIdList.count);
            [self searchRostersByidArray:[NSArray arrayWithArray:rostIdList]];
        }
    }];
}

// 批量搜索用户
- (void)searchRostersByidArray:(NSArray *)idArray {
    [[[BMXClient sharedClient] rosterService] searchRostersByRosterIdList:idArray forceRefresh:NO completion:^(NSArray<BMXRoster *> *rosterList, BMXError *error) {
        [HQCustomToast hideWating];

        if (!error) {
            MAXLog(@"%lu", (unsigned long)rosterList.count);
            self.rosterArray = [NSArray arrayWithArray:rosterList];
            [self.rosterListTableView reloadData];
        } else {
            
        }
    }];
}

// 删除好友
-  (void)removeRoster:(NSInteger)rosterId {
    MAXLog(@"删除好友");
    [[[BMXClient sharedClient] rosterService] removeRosterById:rosterId withCompletion:^(BMXError *error) {
        [self getAllRoster];
    }];
}

// 拒绝加好友申请
- (void)declineRosterById:(NSInteger)roster reason:(NSString *)reason {
    [[[BMXClient sharedClient] rosterService] declineRosterById:roster withReason:reason completion:^(BMXError *error) {
        
    }];
}

#pragma mark - listener
// 用户B同意用户A的加好友请求后，用户A会收到这个回调
- (void)friendAddedByUser:(long long)userId {
     MAXLog(@"对方%lld同意好友的请求", userId);
}

// 用户B申请加A为好友后，用户A会收到这个回调
- (void)friendDidRecivedAppliedFromUser:(long long)userId message:(NSString *)message {
    MAXLog(@"收到%lld添加好友的请求", userId);
}

// 用户B拒绝用户A的加好友请求后，用户A会收到这个回调
- (void)friendDidApplicationDeclinedFromUser:(long long)userId reson:(NSString *)reason {
    
}

//  用户B删除与用户A的好友关系后，用户A会收到这个回调
- (void)friendRemovedByUser:(long long)userId {
    
}

//  用户B同意用户A的加好友请求后，用户A会收到这个回调
- (void)friendDidApplicationAcceptedFromUser:(long long)userId {
    
}

- (void)addFriend {
    RosterSearchViewController *vc = [[RosterSearchViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [vc setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)jumpToScanVC {
    ScanViewController *vc = [[ScanViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated: YES];
}

- (void)jumpToCreateGroup {
    GroupCreateViewController* ctrl = [[GroupCreateViewController alloc] init];
    ctrl.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:ctrl animated:YES];
}

- (void)addToBlackList:(NSInteger)userId {
    [[[BMXClient sharedClient] rosterService] addToBlockList:userId
                                              withCompletion:^(BMXError *error) {
                                                  if (!error) {
                                                      MAXLog(@"添加成功")
                                                      [self getAllRoster];
                                                  } else {
                                                      [HQCustomToast showDialog:[NSString stringWithFormat:@"%@", error.errorMessage] time:2];
                                                  }
                                              }];
}

- (void)clickAddButton:(UIButton *)button {
    [self.menuViewManager show];
    self.menuViewManager.view.delegate = self;
}

#pragma mark - delegate

- (void)menuViewDidSelectbutton:(UIButton *)button {
    if ([button.orderTags isEqualToString:@"添加好友"]) {
        [self addFriend];
    } else if ([button.orderTags isEqualToString:@"创建群组"]) {
        [self jumpToCreateGroup];
    } else {
        [self jumpToScanVC];
    }
}

#pragma mark - TableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.tag == 0 || self.tag == 1) {
        return 2;
    } else {
        return 1;
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.tag == 0) {
        if (section == 0) {
            return self.actionArray.count;
        } else {
            return self.rosterArray.count ? self.rosterArray.count : 0;
        }
    } else if (self.tag == 1){
        if (section == 0) {
            return self.groupTableviewCellArray.count;
        } else {
            return self.groupArray.count ? self.groupArray.count : 0;
        }
    } else if (self.tag == 2) {
        return self.supportArray.count ? self.supportArray.count : 0;
    } else {
        return self.meetingArray.count ? self.meetingArray.count : 0;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 63.f;
    } else {
        return 60.f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
     ImageTitleBasicTableViewCell *cell = [ImageTitleBasicTableViewCell ImageTitleBasicTableViewCellWith:tableView];
    if (self.tag == 0) { // 好友列表
        if (indexPath.section == 0) {
            NSString *titleStr = [NSString stringWithFormat:@"%@", self.actionArray[indexPath.row]];
            [cell refreshByTitle:titleStr];
        } else {
            BMXRoster *roster = self.rosterArray[indexPath.row];
            [cell refresh:roster];
        }
    } else if (self.tag == 1) { // 群组列表
        if (indexPath.section == 0) {
            NSString *titleStr = [NSString stringWithFormat:@"%@", self.groupTableviewCellArray[indexPath.row]];
            [cell refreshByTitle:titleStr];
            if ([titleStr isEqualToString:@"群申请列表"] || [titleStr isEqualToString: @"群聊系统消息"]) {
                cell.avatarImg.image = [UIImage imageNamed: [NSString stringWithFormat:@"group_application"]];
            }
        } else {
            BMXGroup *group = self.groupArray[indexPath.row];
            [cell refreshByGroup:group];
        }
    } else if (self.tag == 2){
        BMXRoster *roster = self.supportArray[indexPath.row];
        [cell refreshSupportRoster:roster];
    } else {
//        NSString *titleStr = [NSString stringWithFormat:@"%@", self.actionArray[indexPath.row]];
        [cell refreshByTitle:[NSString stringWithFormat:@"会议室ID:%@", self.meetingArray[indexPath.row]]];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.tag == 0) {
        if (indexPath.section == 0) {
            NSString *string = self.actionArray[indexPath.row];
            if ([string isEqualToString:@"好友申请与通知"]) {
                RosterDetailViewController *vc = [[RosterDetailViewController alloc] init];
                vc.hidesBottomBarWhenPushed = YES;
                [self.navigationController pushViewController:vc animated:YES];
            }
        } else {
            BMXRoster *roster = self.rosterArray[indexPath.row];
            LHChatVC *vc = [[LHChatVC alloc] initWithRoster:roster messageType:BMXMessageTypeSingle];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if (self.tag == 1) {
        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
//                GroupCreateViewController* ctrl = [[GroupCreateViewController alloc] init];
//                ctrl.hidesBottomBarWhenPushed = YES;
//
//                [ctrl hidesBottomBarWhenPushed];
//                [self.navigationController pushViewController:ctrl animated:YES];
//            } else if(indexPath.row == 1) {
//                GroupApplyViewController *vc = [[GroupApplyViewController alloc] init];
//                vc.hidesBottomBarWhenPushed = YES;
//                [self.navigationController pushViewController:vc animated:YES];
//
//            } else {
                GroupInviteViewController *VC = [[GroupInviteViewController alloc] init];
                VC.hidesBottomBarWhenPushed = YES;

                [self.navigationController pushViewController:VC animated:YES];
            }
            
        } else {
            BMXGroup *group = self.groupArray[indexPath.row];
            
            LHChatVC *vc = [[LHChatVC alloc] initWithGroupChat:group messageType:BMXMessageTypeGroup];
            vc.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:vc animated:YES];
        }
    } else if (self.tag == 2) {
        BMXRoster *roster = self.supportArray[indexPath.row];
        LHChatVC *vc = [[LHChatVC alloc] initWithRoster:roster messageType:BMXMessageTypeSingle];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        
        IMAcount *acount = [IMAcountInfoStorage loadObject];
        
        NSNumber *number = self.meetingArray[indexPath.row];
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
              ms.delegate = self;
              NSDictionary *paramDict = @{
                                          kMeetingParam_Username: acount.usedId,
                                          kMeetingParam_MeetingNumber:[number stringValue],
                                          };
        
        MobileRTCMeetError ret = [ms joinMeetingWithDictionary:paramDict];
        
        if (ret == MobileRTCMeetError_Success) {
            NSString *messageTest = [NSString stringWithFormat:@"%@ 加入会议室", acount.usedId];
            BMXMessageObject *message = [[BMXMessageObject alloc] initWithBMXMessageText:messageTest
                                                                                  fromId:[acount.usedId longLongValue]
                                                                                    toId:6597373638528 type:BMXMessageTypeSingle
                                                                          conversationId:6597373638528];
            [[[BMXClient sharedClient] chatService] sendMessage:message];
        }
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 || self.tag != 0) {
        return NO;
    }
    return YES;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 添加一个删除按钮
    UITableViewRowAction *deleteRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除"handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        MAXLog(@"点击了删除");
        BMXRoster *roster = self.rosterArray[indexPath.row];
        [self removeRoster:roster.rosterId];
        MAXLog(@"删除动作");
        
       
    }];
    // 删除一个置顶按钮
    UITableViewRowAction *topRowAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"加入黑名单"handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        MAXLog(@"点击了点入黑名单");
        BMXRoster *roster = self.rosterArray[indexPath.row];

        [self addToBlackList:roster.rosterId];
    }];
    topRowAction.backgroundColor = [UIColor blueColor];
    
    return @[deleteRowAction, topRowAction];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

-(void)indexDidChangeForSegmentedControl:(UISegmentedControl *)sender {
    
    [self.tipView removeFromSuperview];
    
    [self.menuViewManager hide];
    NSInteger selecIndex = sender.selectedSegmentIndex;
    switch(selecIndex){
        case 0:
        {
            sender.selectedSegmentIndex=0;
            self.tag = 0;
            
            [self.groupListTableView setHidden:YES];
            [self.rosterListTableView setHidden:NO];
            [self.supportListTableView setHidden:YES];
            [self.meetingsTableView setHidden:YES];

            [self selectViewAnimationWithTag:self.tag];
            [self.rosterListTableView reloadData];

            break;
        }
            
        case 1:
        {
            sender.selectedSegmentIndex = 1;
            self.tag = 1;

            [self.groupListTableView setHidden:NO];
            [self.rosterListTableView setHidden:YES];
            [self.supportListTableView setHidden:YES];
            [self.meetingsTableView setHidden:YES];

            
            [self getGroupTableViewDatasource];
            
            [self selectViewAnimationWithTag:self.tag];
            break;
        }
        case 2: {
            sender.selectedSegmentIndex = 2;
            self.tag = 2;
            [self.meetingsTableView setHidden:YES];
            [self.groupListTableView setHidden:YES];
            [self.rosterListTableView setHidden:YES];
            [self.supportListTableView setHidden:NO];
            
            [self selectViewAnimationWithTag:self.tag];
            
            
            [self getSupportData];
            [self.supportListTableView reloadData];

            
            if (![self isShowSupportData]) {
                [self.view insertSubview:self.tipView aboveSubview:self.supportListTableView];
            } else {
                [self.tipView removeFromSuperview];
            }
            
            break;
            
        }
            
        case 3: {
            sender.selectedSegmentIndex = 3;
            self.tag = 3;
            [self.groupListTableView setHidden:YES];
            [self.rosterListTableView setHidden:YES];
            [self.supportListTableView setHidden:YES];
            [self.meetingsTableView setHidden:NO];

            [self selectViewAnimationWithTag:self.tag];
            [self getMeettings];
            [self.meetingsTableView reloadData];
            if (![self isShowSupportData]) {
                [self.view insertSubview:self.tipView aboveSubview:self.supportListTableView];
            } else {
                [self.tipView removeFromSuperview];
            }
                            
            break;
        }
    
            
            
        default:
            break;
    }
}

- (void)getGroupTableViewDatasource {
    self.groupTableviewCellArray = [GroupListTableViewAdapter tableViewCellArray];
    
    [HQCustomToast showWating];
    [GroupListTableViewAdapter getGroupListcompletion:^(NSArray<BMXGroup *> * _Nonnull group, NSString * _Nonnull errmsg) {
        [HQCustomToast hideWating];
        if (![errmsg length]) {
            self.groupArray = group;
        } else {
            [HQCustomToast showDialog:errmsg];
        }
        [self.groupListTableView reloadData];
    }];
}

- (void)selectViewAnimationWithTag:(NSInteger)tag {
    if (tag == 0) {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectView.x = 17;
        }];
    } else if(tag == 1) {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectView.x = 17 + (23 + 40) ;
        }];
    } else if(tag == 2){
        [UIView animateWithDuration:0.2 animations:^{
            self.selectView.x = 17 + (23 + 40) *2;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.selectView.x = 17 + (23 + 40) *3;
        }];
    }
}

- (NSArray *)actionArray {
    return @[@"好友申请与通知"];
}

- (UITableView *)rosterListTableView {
    if (!_rosterListTableView) {
        _rosterListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NavHeight, MAXScreenW, MAXScreenH
                                                                    - NavHeight- 64) style:UITableViewStylePlain];
        _rosterListTableView.bounces = NO;
        _rosterListTableView.delegate = self;
        _rosterListTableView.dataSource = self;
        _rosterListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        UIView *view =  [[UIView alloc] init];
        _rosterListTableView.tableHeaderView = view;
        view.backgroundColor  = BMXCOLOR_HEX(0xf8f8f8);
        _rosterListTableView.tableHeaderView.height = 10;
        [_rosterListTableView registerClass:[ImageTitleBasicTableViewCell class] forCellReuseIdentifier:@"ImageTitleBasicTableViewCell"];
        [self.view addSubview:_rosterListTableView];
    }
    return _rosterListTableView;
}

- (UITableView *)groupListTableView {
    if (!_groupListTableView) {
        _groupListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NavHeight, MAXScreenW, MAXScreenH
                                                                             - NavHeight- 64) style:UITableViewStylePlain];
        _groupListTableView.bounces = NO;
        _groupListTableView.delegate = self;
        _groupListTableView.dataSource = self;
        
        _groupListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        UIView *view =  [[UIView alloc] init];
        _groupListTableView.tableHeaderView = view;
        view.backgroundColor  = BMXCOLOR_HEX(0xf8f8f8);
        _groupListTableView.tableHeaderView.height = 10;
        
        [_groupListTableView registerClass:[ImageTitleBasicTableViewCell class] forCellReuseIdentifier:@"ImageTitleBasicTableViewCell"];
        [self.view addSubview:_groupListTableView];
    }
    return _groupListTableView;
}

- (UITableView *)supportListTableView {
    if (!_supportListTableView) {
        _supportListTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NavHeight, MAXScreenW, MAXScreenH
                                                                            - NavHeight- 64) style:UITableViewStylePlain];
        _supportListTableView.bounces = NO;
        _supportListTableView.delegate = self;
        _supportListTableView.dataSource = self;
        _supportListTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        UIView *view =  [[UIView alloc] init];
        _supportListTableView.tableHeaderView = view;
        view.backgroundColor  = BMXCOLOR_HEX(0xf8f8f8);
        _supportListTableView.tableHeaderView.height = 10;
        
        [_supportListTableView registerClass:[ImageTitleBasicTableViewCell class] forCellReuseIdentifier:@"ImageTitleBasicTableViewCell"];
        [self.view addSubview:_supportListTableView];
    }
    return _supportListTableView;
    
}

- (UITableView *)meetingsTableView {
    if (!_meetingsTableView) {
        _meetingsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NavHeight, MAXScreenW, MAXScreenH
                                                                            - NavHeight- 64) style:UITableViewStylePlain];
        _meetingsTableView.bounces = NO;
        _meetingsTableView.delegate = self;
        _meetingsTableView.dataSource = self;
        _meetingsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        UIView *view =  [[UIView alloc] init];
        _meetingsTableView.tableHeaderView = view;
        view.backgroundColor  = BMXCOLOR_HEX(0xf8f8f8);
        _meetingsTableView.tableHeaderView.height = 10;
        
        [_meetingsTableView registerClass:[ImageTitleBasicTableViewCell class] forCellReuseIdentifier:@"ImageTitleBasicTableViewCell"];
        [self.view addSubview:_meetingsTableView];
    }
    return _meetingsTableView;
    
}

- (UIView *)selectView {
    if (!_selectView) {
        _selectView = [[UIView alloc] init];
        _selectView.frame = CGRectMake(17, NavHeight - 2 , 40, 2);
        _selectView.backgroundColor = BMXCOLOR_HEX(0x009FE8);
        _selectView.layer.cornerRadius = 2;
        _selectView.layer.masksToBounds = YES;
        [self.view addSubview:_selectView];
    }
    return _selectView;
}

- (NSArray *)rosterArray {
    if (!_rosterArray) {
        _rosterArray = [NSArray array];
    }
    return _rosterArray;
}

- (NSArray *)supportArray {
    if (!_supportArray) {
        _supportArray = [NSArray array];
    }
    return _supportArray;
}

- (NSArray *)groupTableviewCellArray {
    if (!_groupTableviewCellArray) {
        _groupTableviewCellArray = [NSArray array];
    }
    return _groupTableviewCellArray;
}

- (NSArray<BMXGroup *> *)groupArray {
    if (!_groupArray) {
        _groupArray = [NSArray array];
    }
    return _groupArray;
}

- (NSArray *)meetingArray {
    if (!_meetingArray) {
        _meetingArray = [NSArray array];
        
    }
    return _meetingArray;
}
+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)setUpNavItem{
    UIView *navigationBar = [[UIView alloc]  initWithFrame:CGRectMake(0, 0, MAXScreenW, NavHeight)];
    [self.view addSubview:navigationBar];
    self.navigationBar = navigationBar;
    
    
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems: @[@"好友", @"群组", @"支持",@"会议室"]];
//                                   initWithFrame:CGRectMake(16, 10, 32 * 3, 30)];
//    
    [control setBackgroundImage:[self imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [control setBackgroundImage:[self imageWithColor:[UIColor clearColor]] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    
    UIImage *_dividerImage= [self imageWithColor:[UIColor clearColor]];
            [control setDividerImage:_dividerImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  
  
    control.frame = CGRectMake(5, MAXIsFullScreen ? 28 + 26 :  28 ,( 190/3.0 )*4.0, 25);
    control.tintColor = [UIColor whiteColor];
    
    [control setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"PingFangSC-Medium" size:T5_30PX], NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateNormal];
    [control setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"PingFangSC-Medium" size:T5_30PX], NSForegroundColorAttributeName:[UIColor blackColor]} forState:UIControlStateSelected];
    control.layer.borderColor = [UIColor whiteColor].CGColor;
    control.selectedSegmentIndex = 0;
    [control addTarget:self action:@selector(indexDidChangeForSegmentedControl:) forControlEvents:UIControlEventValueChanged];
    [navigationBar addSubview:control];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(clickAddButton:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"common_add"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"common_add"] forState:UIControlStateHighlighted];

    button.frame = CGRectMake(MAXScreenW - 10 - 30, MAXIsFullScreen ? 28 + 26 :  28 , 30,25);
    [navigationBar addSubview:button];
    
    CGRect frame = CGRectMake(0, self.navigationBar.height - 0.5, self.navigationBar.width, 0.25);
    UIImageView *bottomSepImageView = [[UIImageView alloc] initWithFrame:frame];
    [navigationBar addSubview:bottomSepImageView];
    bottomSepImageView.backgroundColor = kColorC4_5;
    bottomSepImageView.clipsToBounds = NO;
    bottomSepImageView.layer.shadowOffset = CGSizeMake(0,-0.5);
    bottomSepImageView.layer.shadowRadius = 5;
    bottomSepImageView.layer.shadowOpacity = 0.5;
}

- (MenuViewManager *)menuViewManager {
    if (!_menuViewManager) {
        _menuViewManager = [MenuViewManager sharedMenuViewManager];

    }
    return _menuViewManager;
}

- (MaxEmptyTipView *)tipView {
    if (!_tipView) {
        
        CGFloat navh = kNavBarHeight;
        if (MAXIsFullScreen) {
            navh  = kNavBarHeight + 24;
        }
        _tipView = [[MaxEmptyTipView alloc] initWithFrame:CGRectMake(0, navh + 1 , MAXScreenW, MAXScreenH - navh - 37) type:MaxEmptyTipTypeContactSupport];
    }
    return _tipView;
}


#pragma mark == delegate of create group
- (void) setNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onGrouplistChange) name:@"KGroupListModified" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getAllRoster) name:@"RefreshContactList" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideMenu) name:@"HideMenu" object:nil];
}

- (void)onGrouplistChange {
    
    if (self.tag == 1) {
        MAXLog(@"1");
         [self getGroupTableViewDatasource];
    }
}

@end
