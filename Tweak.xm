/* =====================================================================
 * SunflowerTweak — 向日葵 15.5.10 去广告 / 功能增强 (TrollStore dylib)
 * Bundle ID : com.oray.sunlogin.controlclient
 * 依赖      : Logos (Theos) + Substrate/ElleKit
 *
 * 功能开关全部内置于「我的 → 设置」页面底部，采用 UISwitch 样式，
 * 配置通过 NSUserDefaults 持久化，修改后即时生效。
 * ===================================================================== */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-property-no-attribute"
#pragma clang diagnostic ignored "-Wnullability-completeness"

/* ---------------------------------------------------------------------
 * 编译期类声明（这些类来自被注入的 App，本地仅用于类型检查）
 * --------------------------------------------------------------------- */
/* 注意：Logos 会为 %hook 的类自动生成 @class 前向声明，
 * 若这里只用 category 扩展前向声明的类会编译失败，
 * 因此统一用完整 @interface 声明。父类仅用于编译期类型检查。 */
@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *listTableView;
- (void)sf_switchChanged:(UISwitch *)sender;
@end

@interface MainTabBarController : UITabBarController
- (void)sf_refreshTabs;
@end

@interface ADFullScreenViewController : UIViewController
- (void)skipBtnDidClicked:(id)sender;
@end

@interface NewMineViewController : UIViewController
@end

@interface NewDiscoverViewController : UIViewController
@end

@interface GADManager : NSObject
@end

@interface WMADManager : NSObject
@end

@interface TakuADManager : NSObject
@end

@interface InsertAdManager : NSObject
@end

@interface ADInfoManager : NSObject
@end

/* =====================================================================
 * 1. 偏好配置
 * ===================================================================== */
static NSString * const kSFPrefsPrefix = @"com.oray.sunflower.tweak.";

static BOOL SFBool(NSString *key, BOOL defaultValue) {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:[kSFPrefsPrefix stringByAppendingString:key]];
    return value ? [value boolValue] : defaultValue;
}

static void SFSetBool(NSString *key, BOOL value) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:value forKey:[kSFPrefsPrefix stringByAppendingString:key]];
    [ud synchronize];
}

/* 开关项定义：key / 标题 / 副标题 / 默认值 */
static NSArray<NSDictionary *> *SFOptions(void) {
    static NSArray *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            @{ @"key": @"hideDiscover",  @"title": @"隐藏「发现」标签",
               @"sub": @"移除底部发现入口，立即生效", @"def": @YES },
            @{ @"key": @"removeSplash",  @"title": @"屏蔽开屏广告",
               @"sub": @"启动不再等待广告", @"def": @YES },
            @{ @"key": @"removeInsert",  @"title": @"屏蔽插屏广告",
               @"sub": @"切回前台不再弹广告", @"def": @YES },
            @{ @"key": @"removeFeed",    @"title": @"屏蔽信息流广告",
               @"sub": @"发现页/列表页广告位", @"def": @YES },
            @{ @"key": @"blockAdFetch",  @"title": @"阻止广告数据拉取",
               @"sub": @"更彻底，减少联网与耗电", @"def": @YES },
            @{ @"key": @"removeUpdate",  @"title": @"屏蔽版本更新提醒",
               @"sub": @"实验项，关闭更新检测", @"def": @NO },
            @{ @"key": @"removeRate",    @"title": @"屏蔽评分弹窗",
               @"sub": @"点击评分无反应", @"def": @YES },
            @{ @"key": @"hideActivity",  @"title": @"隐藏活动推广位",
               @"sub": @"实验项，「我的」页活动入口", @"def": @NO },
            @{ @"key": @"autoSkipSplash",@"title": @"开屏广告自动跳过",
               @"sub": @"实验项，出现开屏时自动跳过", @"def": @NO },
        ];
    });
    return options;
}

/* 设置页原始 section 数（hook numberOfSections 时记录） */
static NSInteger SFOrigSections = 0;

/* =====================================================================
 * 2. 设置面板：在 SettingsViewController  tableView 末尾追加开关区
 * ===================================================================== */
%hook SettingsViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger original = %orig;
    SFOrigSections = original;
    return original + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SFOrigSections) {
        return SFOptions().count;
    }
    return %orig;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SFOrigSections) {
        NSDictionary *option = SFOptions()[indexPath.row];
        static NSString *cellID = @"SunflowerToggleCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                          reuseIdentifier:cellID];
            UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
            [sw addTarget:self action:@selector(sf_switchChanged:)
         forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = sw;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.numberOfLines = 1;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.font = [UIFont systemFontOfSize:11.0];
            cell.detailTextLabel.textColor = [UIColor grayColor];
        }
        cell.textLabel.text = option[@"title"];
        cell.detailTextLabel.text = option[@"sub"];
        UISwitch *sw = (UISwitch *)cell.accessoryView;
        sw.tag = indexPath.row;
        [sw setOn:SFBool(option[@"key"], [option[@"def"] boolValue]) animated:NO];
        return cell;
    }
    return %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SFOrigSections) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UISwitch *sw = (UISwitch *)cell.accessoryView;
        if ([sw isKindOfClass:[UISwitch class]]) {
            [sw setOn:!sw.isOn animated:YES];
            [self sf_switchChanged:sw];
        }
        return;
    }
    %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SFOrigSections) return 54.0;
    return %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == SFOrigSections) return 30.0;
    return %orig;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == SFOrigSections) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                             tableView.bounds.size.width, 30.0)];
        header.backgroundColor = [UIColor clearColor];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 4,
                             tableView.bounds.size.width - 32, 22)];
        label.text = @"向日葵增强 · 去广告 (TrollStore)";
        label.font = [UIFont boldSystemFontOfSize:13.0];
        label.textColor = [UIColor grayColor];
        [header addSubview:label];
        return header;
    }
    return %orig;
}

/* 开关事件：写入偏好并广播通知，使主界面即时刷新 */
%new
- (void)sf_switchChanged:(UISwitch *)sender {
    NSInteger row = sender.tag;
    NSArray *options = SFOptions();
    if (row < 0 || row >= (NSInteger)options.count) return;
    NSDictionary *option = options[row];
    NSString *key = option[@"key"];
    SFSetBool(key, sender.isOn);

    if ([key isEqualToString:@"hideDiscover"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SunflowerDiscoverChanged"
                                                            object:nil];
    }
    NSLog(@"[SunflowerTweak] set %@ = %@", key, sender.isOn ? @"ON" : @"OFF");
}

%end

/* =====================================================================
 * 3. 主 TabBar：隐藏「发现」标签 + 屏蔽主界面广告 + 更新检测
 * ===================================================================== */
%hook MainTabBarController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sf_refreshTabs)
                                                 name:@"SunflowerDiscoverChanged"
                                               object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sf_refreshTabs];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self sf_refreshTabs];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"SunflowerDiscoverChanged"
                                                  object:nil];
    %orig;
}

/* 过滤掉发现页对应的 tab */
%new
- (void)sf_refreshTabs {
    if (!SFBool(@"hideDiscover", YES)) return;

    NSArray *controllers = self.viewControllers;
    if (!controllers || controllers.count <= 1) return;

    NSMutableArray *kept = [NSMutableArray arrayWithArray:controllers];
    NSMutableIndexSet *toRemove = [NSMutableIndexSet indexSet];

    [controllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
        UIViewController *target = vc;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)vc;
            target = nav.viewControllers.firstObject ?: vc;
        }
        BOOL isDiscover = NO;
        Class discoverClass = objc_getClass("NewDiscoverViewController");
        if (discoverClass && [target isKindOfClass:discoverClass]) isDiscover = YES;

        NSString *title = vc.tabBarItem.title ?: target.title ?: @"";
        if ([title rangeOfString:@"发现"].location != NSNotFound ||
            [title rangeOfString:@"Discover" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            isDiscover = YES;
        }
        if (isDiscover) [toRemove addIndex:idx];
    }];

    if (toRemove.count > 0 && (kept.count - toRemove.count) >= 1) {
        [kept removeObjectsAtIndexes:toRemove];
        [UIView performWithoutAnimation:^{
            [self setViewControllers:kept animated:NO];
        }];
        NSLog(@"[SunflowerTweak] removed %lu discover tab(s)", (unsigned long)toRemove.count);
    }
}

/* 主界面广告位 */
- (void)checkAD {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}

- (void)updateADWithAdInfo:(id)info {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}

- (void)adInfoLoadedWithKey:(id)key isNeedUpdate:(BOOL)needUpdate {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}

- (void)updateReservedADWithADInfo:(id)info showViewController:(id)vc {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}

- (void)pushReserveADWithUrl:(id)url insideJump:(BOOL)insideJump {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}

/* 版本更新检测（可选关闭） */
- (void)checkVersionAvailabilityWithFinish:(id)finish {
    if (SFBool(@"removeUpdate", NO)) return;
    %orig;
}

%end

/* =====================================================================
 * 4. 开屏广告：Google / 微博(WindMill) / Taku 三条链路
 * ===================================================================== */
%hook GADManager

/* AdMob 开屏：拦截展示并主动回调 finished，避免启动流程卡住 */
- (void)showAdIfAvailableWithRootViewController:(id)rootVC
                                          scene:(id)scene
                                  shownHandler:(void (^)(void))shown
                                  clickHandler:(void (^)(void))click
                               finishedHandler:(void (^)(void))finished {
    if (SFBool(@"removeSplash", YES)) {
        if (finished) finished();
        return;
    }
    %orig;
}

/* 不预加载开屏广告 */
- (void)loadSplashADWithComplete:(void (^)(void))complete
                          scene:(id)scene
                      isPreload:(BOOL)isPreload {
    if (SFBool(@"removeSplash", YES)) return;
    %orig;
}

%end

%hook WMADManager
- (void)showSplashAd {
    if (SFBool(@"removeSplash", YES)) return;
    %orig;
}
%end

%hook TakuADManager
- (void)showSplashAd:(id)arg1 {
    if (SFBool(@"removeSplash", YES)) return;
    %orig;
}
%end

/* 可选兜底：开屏出现时自动点击跳过 */
%hook ADFullScreenViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (SFBool(@"autoSkipSplash", NO)) {
        [self performSelector:@selector(skipBtnDidClicked:)
                   withObject:nil
                   afterDelay:0.3];
    }
}
%end

/* =====================================================================
 * 5. 插屏广告：回前台触发的插屏
 * ===================================================================== */
%hook InsertAdManager
- (void)didBecomeActive:(id)notification {
    if (SFBool(@"removeInsert", YES)) return;
    %orig;
}
%end

/* =====================================================================
 * 6. 发现页信息流广告
 * ===================================================================== */
%hook NewDiscoverViewController
- (void)refreshAd {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}
- (void)getInsertAd {
    if (SFBool(@"removeInsert", YES)) return;
    %orig;
}
- (void)adInfoLoadedWithKey:(id)key isNeedUpdate:(BOOL)needUpdate {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}
- (void)updateADWithAdsInfoKey:(id)key {
    if (SFBool(@"removeFeed", YES)) return;
    %orig;
}
%end

/* =====================================================================
 * 7. 广告数据拉取（深度去广告）：阻止各广告位向服务器请求素材
 * ===================================================================== */
%hook ADInfoManager
- (void)updateStartupAD             { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateHotStartupAD          { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDeviceListAD          { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDeviceTopAD           { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDeviceReserveAD       { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateMineReserveAD         { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateClientActivityAD      { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateAwesunDiscoverAD      { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateRemoteEndAD           { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateRemoteEndInsertAD     { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateRemoteFlowAD          { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateWaitingFlowAD         { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDiscoverFlowAD        { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)requestNextFrequencyCache   { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
%end

/* =====================================================================
 * 8. 其它优化：「我的」页评分弹窗 / 活动推广位
 * ===================================================================== */
%hook NewMineViewController
- (void)rateSunlogin {
    if (SFBool(@"removeRate", YES)) return;
    %orig;
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (!SFBool(@"hideActivity", NO)) return;
    NSArray *keys = @[@"activityLineView", @"activityBgView1", @"activityBgView3",
                      @"activityLabel_1", @"activityLabel_2", @"activityLabel_3"];
    for (NSString *key in keys) {
        @try {
            id view = [self valueForKey:key];
            if ([view isKindOfClass:[UIView class]]) {
                ((UIView *)view).hidden = YES;
            }
        } @catch (NSException *exception) { /* 忽略不存在的键 */ }
    }
}
%end

/* =====================================================================
 * 9. 构造入口：加载日志
 * ===================================================================== */
%ctor {
    NSLog(@"[SunflowerTweak] loaded. bundle=%@  ver=%@",
          [[NSBundle mainBundle] bundleIdentifier],
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}

#pragma clang diagnostic pop
