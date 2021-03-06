//
//  LoginViewController.m
//  MaxIM
//
//  Created by 韩雨桐 on 2019/11/16.
//  Copyright © 2019 hyt. All rights reserved.
//

#import "LoginViewController.h"
#import "PravitcyViewController.h"
#import "ScanViewController.h"
#import "LoginView.h"
#import "AppDelegate.h"

#import "WXApi.h"
#import "WechatApi.h"
#import <floo-ios/BMXClient.h>
#import "IMAcountInfoStorage.h"
#import "IMAcount.h"
#import "MAXGlobalTool.h"
#import "GetTokenApi.h"
#import "AppIDManager.h"
#import "NotifierBindApi.h"
#import "BindOpenIdApi.h"
#import "UserMobileBindApi.h"
#import "AppUserInfoPwdApi.h"
#import "UserMobileBindWithSignApi.h"

#import "TokenIdApi.h"
#import "AccountManagementManager.h"
#import "LogViewController.h"

#import "SDKConfigViewController.h"

#import <floo-ios/BMXHostConfig.h>

#import "PrivacyView.h"

@interface LoginViewController ()<LoginViewConfigProtocol, SDKConfigViewControllerProtocl, PrivacyProtocol>

@property (nonatomic, strong) LoginViewConfig *config;
@property (nonatomic,copy) NSString *scanConsuleUserName;
@property (nonatomic, strong) NSDictionary *scanConsuleResultDic;

@end

@implementation LoginViewController

+ (UIViewController *)loginViewWithViewControllerWithNavigation{
    
    LoginViewController *loginViewController =  [[LoginViewController alloc] initWithViewType:LoginVCTypePasswordLogin];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loginViewController];
    return nav;
}


- (instancetype)initWithViewType:(LoginVCType)viewType {
 
    self = [self init];
    if (self) {
        self.config = [[LoginViewConfig alloc] initWithViewType:viewType];
        self.config.delegate = self;
        [self setupUI];
    }
    return self;

}

- (void)setupUI {
    
    LoginView *loginView = [self.config creteLoginView];
    [self.view addSubview:loginView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wechatSuccessloginIM) name:@"wechatloginsuccess" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToRegistVC:) name:@"wechatloginsuccess_newuser" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputUserTextFeild:) name:@"ScanConsule" object:nil];
    
    [self.config setAppid:[AppIDManager sharedManager].appid.appId];

    UIWindow *keyWindow;
    if (@available(iOS 13.0, *)) {
        keyWindow = [UIApplication sharedApplication].windows.firstObject;
    }else {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    [PrivacyView showPrivacyWithMaxTimeInterval:-1 view:self.view staticKey:@"maxim_privacy" privacyUrl:@"https://www.maximtop.com/privacy" delegate:self];

    
}

#pragma mark - delegate

- (void)popViewController {
 
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)popRootViewController {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)pushToSmsLogin {
    
    LoginViewController *smsLoginViewController = [[LoginViewController alloc] initWithViewType:LoginVCTypeCaptchLogin];
    [self.navigationController pushViewController:smsLoginViewController animated:YES];
}

- (void)pushToRegister {
    
    LoginViewController *regiesterViewController = [[LoginViewController alloc] initWithViewType:LoginVCTypeRegister];
    [self.navigationController pushViewController:regiesterViewController animated:YES];
}

- (void)showUserPrivacy {
    PravitcyViewController *vc =  [[PravitcyViewController alloc] initWithTitle:@"用户隐私协议" url:@"https://www.maximtop.com/privacy"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showUserTerms {
    PravitcyViewController *vc =  [[PravitcyViewController alloc] initWithTitle:@"用户服务条款" url:@"https://www.maximtop.com/terms/"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)beginScanQRCode {
    
    ScanViewController *vc = [[ScanViewController alloc] init];
    vc.modalPresentationStyle =  UIModalPresentationFullScreen;
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)showLogVC {
    MAXLog(@"show log vc");
    
    LogViewController *vc = [[LogViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
}

// 微信登录
- (void)loginByWechat {
 
    //        方法一：只有手机安装了微信才能使用
    if ([WXApi isWXAppInstalled]) {
        SendAuthReq *req = [[SendAuthReq alloc] init];
        //这里是按照官方文档的说明来的此处我要获取的是个人信息内容
        req.scope = @"snsapi_userinfo";
        req.state = @"login";
        //向微信终端发起SendAuthReq消息
        [WXApi sendReq:req completion:^(BOOL success) {
            
        }];
    } else {
        [HQCustomToast showDialog:@"请安装微信客户端"];
        MAXLog(@"安装微信客户端");
    }
}

// 用户名登录
- (void)signByName:(NSString *)name password:(NSString *)password {
    [self loginAndEntryMainVCWithName:name password:password];
}

// 验证码登录
- (void)signByPhone:(NSString *)phone captch:(NSString *)captch {
    MAXLog(@"验证码登录");
    
    AppUserInfoPwdApi *api = [[AppUserInfoPwdApi alloc] initWithMobile:phone captcha:captch];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            
            if (result.resultData[@"sign"]) {
                LoginViewController *bindUserViewController = [[LoginViewController alloc] initWithViewType:LoginVCTypeRegisterAndBindPhone];
                bindUserViewController.config.sign = result.resultData[@"sign"];
                bindUserViewController.config.phone = phone;
                [self.navigationController pushViewController:bindUserViewController animated:YES];
            } else {
                // 直接登录
                NSString *userName = result.resultData[@"username"];
                NSString *password = result.resultData[@"password"];
                [self loginAndEntryMainVCWithName:userName password:password];
            }
            
        } else if ([result.code isEqualToString:@"10001"]) {
            [HQCustomToast showDialog:@"验证码不正确"];
        }        
    } failureBlock:^(NSError * _Nullable error) {
        [HQCustomToast showNetworkError];
    }];
}



// 用户名注册
- (void)regiesterWithName:(NSString *)name password:(NSString *)password {
    
    [[BMXClient sharedClient] signUpNewUser:name password:password completion:^(BMXUserProfile * _Nonnull profile, BMXError * _Nonnull error) {
        if (!error) {
            [self registerLoginByName:name password:password];
        } else if (error.errorCode == BMXUserAlreadyExist){
            [self.config showErrorText:@"该用户名已存在"];
        } else {
            [HQCustomToast showDialog:error.errorMessage];
        }
    }];
}


// 手机验证码首次登录，进入绑定已有号码页面
- (void)pushToBindUserWithPhone {
    
    LoginViewController *bindNameViewController = [[LoginViewController alloc] initWithViewType:LoginVCTypeBindUserWithPhone];
    bindNameViewController.config.phone = self.config.phone;
    bindNameViewController.config.sign = self.config.sign;
    [self.navigationController pushViewController:bindNameViewController animated:YES];
}


// 手机验证码首次登录，绑定新注册用户
- (void)registerAndBindPhoneUserName:(NSString *)userName
                    password:(NSString *)password {
    // 注册
    [[BMXClient sharedClient] signUpNewUser:userName password:password completion:^(BMXUserProfile * _Nonnull profile, BMXError * _Nonnull error) {
        if (!error) {
            // 登录
            [self registerLoginBindByName:userName password:password];
        } else if (error.errorCode == BMXUserAlreadyExist){
            [self.config showErrorText:@"该用户名已存在"];
        }
    }];
}
// 手机验证码首次登录，绑定已有账号
- (void)bindPhoneWithName:(NSString *)name
                 password:(NSString *)password {
      [self bindPhoneWithUserName:name password:password phone:self.config.phone sign:self.config.sign];
}


// 首次微信登录，绑定新注册用户
- (void)regiesterAndBindWechatWithName:(NSString *)name
                              password:(NSString *)password {
    // 注册
    [[BMXClient sharedClient] signUpNewUser:name password:password completion:^(BMXUserProfile * _Nonnull profile, BMXError * _Nonnull error) {
        if (!error) {
            // 登录
            [self registerLoginBindByName:name password:password];
        } else if (error.errorCode == BMXUserAlreadyExist){
            [self.config showErrorText:@"该用户名已存在"];
        } else {
            [HQCustomToast showDialog:error.errorMessage];
        }
    }];
}

// 首次微信登录，绑定已有账号
- (void)bindWechatWithName:(NSString *)name password:(NSString *)password {
//    [self bindWechatWithUserName:name password:password];
    [self registerLoginBindByName:name password:password];
}



// 绑定手机号
- (void)bindPhone:(NSString *)phone captch:(NSString *)captch {
    UserMobileBindApi *api = [[UserMobileBindApi alloc] initWithMobile:phone captach:captch];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            
        } else if([result.code isEqualToString:@"10015"]) {
            [HQCustomToast showDialog:@"该手机号已绑定"];
        } else if([result.code isEqualToString:@"10001"]) {
            [HQCustomToast showDialog:@"验证码不匹配"];
        }
    } failureBlock:^(NSError * _Nullable error) {
        [HQCustomToast showNetworkError];
    }];
    [self loginBlockdismiss];

    
}



- (void)endLoginView {
    [self disMissViewController];
}

- (void)loginBlockdismiss {
    
    [self willMoveToParentViewController:nil];
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
    
    [UIApplication sharedApplication].delegate.window.rootViewController = [MAXGlobalTool share].rootViewController;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccess" object:nil];
    [[MAXGlobalTool share].rootViewController addIMListener];

}

- (void)editAppid {
       
    SDKConfigViewController *vc = [[SDKConfigViewController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
//    [self showAppIDEditAlert];
}

- (void)sdkconfigdidClickReturn {
    [self.config setAppid:[AppIDManager sharedManager].appid.appId];
    [self.config showWechatButton:[AppIDManager isDefaultAppID]];

}

- (void)pushToBindNickNameWithWechatOpenId:(NSString *)wechatOpenId {
    
    LoginViewController *bindNameViewController = [[LoginViewController alloc] initWithViewType:LoginVCTypeBindUserWithWechat];
    bindNameViewController.config.wechatOpenId = wechatOpenId;
    [self.navigationController pushViewController:bindNameViewController animated:YES];
    
}

- (void)disMissViewController {
    
     [UIApplication sharedApplication].delegate.window.rootViewController = [MAXGlobalTool share].rootViewController;
    
}
#pragma mark - private

- (void)wechatSuccessloginIM {
    IMAcount *account = [IMAcountInfoStorage loadObject];
//    [self signById:[account.usedId integerValue] password:account.password];
    
    [self loginByName:account.userName password:account.password];
}

- (void)loginByName:(NSString *)userName
        password:(NSString *)password {
    [HQCustomToast showWating];
    
    [[BMXClient sharedClient] signInByName:userName password:password completion:^(BMXError * _Nonnull error) {

        [HQCustomToast hideWating];
        if (!error) {
            MAXLog(@"登录成功 username = %@ , password = %@", userName, password);
            
            [self getAppTokenWithName:userName password:password];
            
            [self getProfile];
            
            [self willMoveToParentViewController:nil];
            [self removeFromParentViewController];
            [self.view removeFromSuperview];
            
            [self saveIMAcountName:userName password:password];
            
            [UIApplication sharedApplication].delegate.window.rootViewController = [MAXGlobalTool share].rootViewController;
            [self bindDeviceToken];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccess" object:nil];
//            [HQCustomToast showDialog:@"登录成功"];
            [[MAXGlobalTool share].rootViewController addIMListener];
            
            [self uploadAppIdIfNeededWithUserName:userName];
            
        }else {
            [HQCustomToast showDialog:[NSString stringWithFormat:@"%@",error.errorMessage]];
            
            MAXLog(@"失败 errorCode = %lu ", error.errorCode);
        }
    }];
}

- (void)jumpToRegistVC:(NSNotification *)notify {
    NSDictionary *dict = notify.object;
    if (dict) {
        NSString *openId = [dict objectForKey:@"openid"];
        LoginViewController *regiestervc = [[LoginViewController alloc] initWithViewType:LoginVCTypeRegisterAndBindWechat];
        regiestervc.config.wechatOpenId = openId;
        [self.navigationController pushViewController:regiestervc animated:YES];
    }
}
- (void)inputUserTextFeild:(NSNotification *)noti {
    NSDictionary *dic = noti.object;
    if (dic) {
        self.scanConsuleUserName = dic[@"userName"];
        [self reloadLocalAppID:dic[@"appId"]];
        [self.config setAppid:dic[@"appId"]];
        [self.config setUserName:self.scanConsuleUserName];
    }
    self.scanConsuleResultDic = dic;
}

- (void)showAppIDEditAlert {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"修改AppID"
                                                                   message:@"如果需要更改需要重启客户端"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //响应事件
                                                         //得到文本信息
                                                         for(UITextField *text in alert.textFields){
                                                             MAXLog(@"text = %@", text.text);
                                                             [self reloadLocalAppID:text.text];
                                                             [self.config setAppid:text.text];
                                                             
                                                         }
                                                     }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * action) {
                                                             //响应事件
                                                             MAXLog(@"action = %@", alert.textFields);
                                                         }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"请输入AppID";
        textField.text = [AppIDManager sharedManager].appid.appId;
    }];
    
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)reloadLocalAppID:(NSString *)appid {
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    [appDelegate reloadAppID:appid];

    [self.config showWechatButton:[AppIDManager isDefaultAppID]];
}

- (void)uploadAppIdIfNeededWithUserName:(NSString *)userName {
    if (!self.scanConsuleResultDic) {
        MAXLog(@"scanConsuleResultDic为空，异常");
        return;
    }
    if ([self.scanConsuleUserName isEqualToString:userName]) {
        
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"];
        
        NSString *appid = self.scanConsuleResultDic[@"appId"];
        NSString *userid = self.scanConsuleResultDic[@"uid"];
        
        
        if ([deviceToken length]) {
            NotifierBindApi *api = [[NotifierBindApi alloc] initWithAppID:appid
                                                              deviceToken:deviceToken
                                                             notifierName:@"NotiCer"
                                                                   userID:userid];
            
            [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
                if (result.isOK) {
                    MAXLog(@"bind success");
                                    }
                
            } failureBlock:^(NSError * _Nullable error) {
                MAXLog(@"consule绑定失败");
            }];
            
        } else {
            
        }
        
    }
}

- (void)saveIMAcountName:(NSString *)name password:(NSString *)password {
    
    IMAcount *a = [[IMAcount alloc] init];
    a.isLogin = YES;
    a.password = password;
    a.userName = [NSString stringWithFormat:@"%@", name];
    [IMAcountInfoStorage saveObject: a];
    
}

- (void)bindDeviceToken {
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:@"deviceToken"];
    if ([deviceToken length]) {
        [[[BMXClient sharedClient] userService] bindDevice:deviceToken completion:^(BMXError *error) {
            MAXLog(@"绑定成功%@", deviceToken);
        }];
    }
}

- (void)getProfile{
    [[[BMXClient sharedClient] userService] getProfileForceRefresh:YES completion:^(BMXUserProfile *profile, BMXError *aError) {
        if (!aError) {
            IMAcount *account = [IMAcountInfoStorage loadObject];
            account.usedId = [NSString stringWithFormat:@"%lld", profile.userId];
            account.userName = profile.userName;
            [IMAcountInfoStorage saveObject:account];
            account.appid = [[BMXClient sharedClient] sdkConfig].appID;
            [self saveAccountToLoaclListWithaccount:account];
            
            [[[BMXClient sharedClient] userService] downloadAvatarWithProfile:profile thumbnail:YES progress:^(int progress, BMXError *error) {
                
            } completion:^(BMXUserProfile *profile, BMXError *error) {
                
            }];
        }
        
    }];
}

- (void)getAppTokenWithName:(NSString *)name password:(NSString *)password {
    GetTokenApi *api = [[GetTokenApi alloc] initWithName:name password:password];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            IMAcount *account = [IMAcountInfoStorage loadObject];
            NSDictionary *dic = result.resultData;
            account.token = dic[@"token"];
            [IMAcountInfoStorage saveObject:account];
            MAXLog(@"已获取token");
    
        }
    } failureBlock:^(NSError * _Nullable error) {

    }];
}

// 注册登录之后绑定手机号
- (void)bindPhoneWithUserName:(NSString *)userName
                     password:(NSString *)password
                        phone:(NSString *)phone
                      sign:(NSString *)sign {
    
    GetTokenApi *api = [[GetTokenApi alloc] initWithName:userName password:password];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            IMAcount *account = [IMAcountInfoStorage loadObject];
            NSDictionary *dic = result.resultData;
            account.token = dic[@"token"];
            [IMAcountInfoStorage saveObject:account];
            [self bindPhoneWithPhone:phone sign:sign];
            
        }
    } failureBlock:^(NSError * _Nullable error) {
        
    }];
}


// 注册登录之后绑定微信号
- (void)bindWechatWithUserName:(NSString *)userName
                     password:(NSString *)password {
    
    GetTokenApi *api = [[GetTokenApi alloc] initWithName:userName password:password];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            IMAcount *account = [IMAcountInfoStorage loadObject];
            NSDictionary *dic = result.resultData;
            account.token = dic[@"token"];
            [IMAcountInfoStorage saveObject:account];
            [self bindWechat];
            
        }
    } failureBlock:^(NSError * _Nullable error) {
        
    }];
}

// 绑定手机号
- (void)bindPhoneWithPhone:(NSString *)phone
                         sign:(NSString *)sign {
    [self loginBlockdismiss];

    UserMobileBindWithSignApi *bindApi =  [[UserMobileBindWithSignApi alloc ] initWithMobile:phone sign:sign];
    [bindApi startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
        } else {
            [HQCustomToast showDialog:result.errmsg];
        }
    } failureBlock:^(NSError * _Nullable error) {
        [HQCustomToast showNetworkError];
    }];
}

// 绑定微信
- (void)bindWechat {
    [self loginBlockdismiss];

    BindOpenIdApi *api = [[BindOpenIdApi alloc] initWithopenId:self.config.wechatOpenId];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            [HQCustomToast showDialog:@"绑定成功"];
        } else {
            [HQCustomToast showDialog:result.errmsg];
        }
    } failureBlock:^(NSError * _Nullable error) {
        [HQCustomToast showDialog:@"绑定失败"];
    }];
}


- (void)p_getTokenByID:(NSString *)userID password:(NSString *)password {
    TokenIdApi *api = [[TokenIdApi alloc] initWithUserID:userID password:password];
    [api startWithSuccessBlock:^(ApiResult * _Nullable result) {
        if (result.isOK) {
            IMAcount *account = [IMAcountInfoStorage loadObject];
            NSDictionary *dic = result.resultData;
            account.token = dic[@"token"];
            [IMAcountInfoStorage saveObject:account];
            MAXLog(@"已获取token");
            
        }
    } failureBlock:^(NSError * _Nullable error) {
        
    }];
}

#pragma mark - loginApi

// 直接登录
- (void)loginAndEntryMainVCWithName:(NSString *)name password:(NSString *)password {
    
    MAXLog(@"%@", [[BMXClient sharedClient] sdkConfig].hostConfig.restHost);
    
    [HQCustomToast showWating];
    [[BMXClient sharedClient] signInByName:name password:password completion:^(BMXError *error) {
        [HQCustomToast hideWating];
        if (!error) {
            MAXLog(@"登录成功 username = %@ , password = %@",name, password);
            [self uploadAppIdIfNeededWithUserName:name];

            [self saveLastLoginAppid];
            
            [self getAppTokenWithName:name password:password];
            
            [self getProfile];
            
            [self bindDeviceToken];
            
            [self saveIMAcountName:name password:password];
            
            [self willMoveToParentViewController:nil];
            [self removeFromParentViewController];
            [self.view removeFromSuperview];
            [UIApplication sharedApplication].delegate.window.rootViewController = [MAXGlobalTool share].rootViewController;
            
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccess" object:nil];
            //            [HQCustomToast showDialog:@"登录成功"];
            
            [[MAXGlobalTool share].rootViewController addIMListener];
            
            
        }else {
            MAXLog(@"失败 errorCode = %lu ", error.errorCode);
            [HQCustomToast showDialog:[NSString stringWithFormat:@"%@", error.errorMessage]];
        }
    }];
}

- (void)saveAccountToLoaclListWithaccount:(IMAcount *)account {
    [[AccountManagementManager sharedAccountManagementManager] addAccountUserName:account.userName password:account.password userid:account.usedId appid:account.appid];
}

- (void)saveLastLoginAppid {
    BMXSDKConfig *sdkconfig = [[BMXClient sharedClient] sdkConfig];
    [AppIDManager changeAppid:sdkconfig.appID isSave:YES];
}

// 注册后的登录
- (void)registerLoginByName:(NSString *)name password:(NSString *)password {
    [HQCustomToast showWating];
    [[BMXClient sharedClient] signInByName:name password:password completion:^(BMXError *error) {
        [HQCustomToast hideWating];
        
        if (!error) {
            MAXLog(@"登录成功 username = %@ , password = %@",name, password);
            
            [self uploadAppIdIfNeededWithUserName:name];
            
            [self saveLastLoginAppid];

            [self getAppTokenWithName:name password:password];
            
            [self saveIMAcountName:name password:password];
            
            [self bindDeviceToken];
            
            [self getProfile];
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccess" object:nil];
            
            LoginViewController *bindPhoneViewController = [[LoginViewController alloc] initWithViewType:LoginVCTypeBindPhone];
            [self.navigationController pushViewController:bindPhoneViewController animated:YES];
            
            
        }else {
            MAXLog(@"失败 errorCode = %lu ", error.errorCode);
            [HQCustomToast showDialog:[NSString stringWithFormat:@"%@", error.errorMessage]];
        }
    }];
}

// 登录后需要绑定
- (void)registerLoginBindByName:(NSString *)name password:(NSString *)password {
    [HQCustomToast showWating];
    [[BMXClient sharedClient] signInByName:name password:password completion:^(BMXError *error) {
        [HQCustomToast hideWating];
        
        if (!error) {
            MAXLog(@"登录成功 username = %@ , password = %@",name, password);
            [self uploadAppIdIfNeededWithUserName:name];
            
            [self saveLastLoginAppid];
            
            [self getAppTokenWithName:name password:password];
            
            [self getProfile];
            
            [self bindDeviceToken];
            
            [self saveIMAcountName:name password:password];
            
            if (self.config.phone.length > 0 && self.config.sign.length > 0) {
                [self bindPhoneWithUserName:name password:password phone:self.config.phone sign:self.config.sign];
            }else if (self.config.wechatOpenId.length > 0) {
                [self bindWechatWithUserName:name password:password];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"loginSuccess" object:nil];
            
        }else {
            MAXLog(@"失败 errorCode = %lu ", error.errorCode);
            [HQCustomToast showDialog:[NSString stringWithFormat:@"%@", error.errorMessage]];
        }
    }];
}

@end
