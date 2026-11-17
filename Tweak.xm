/* =====================================================================
 * SunflowerTweak — 向日葵 15.5.10 去广告 / 功能增强 (TrollStore dylib)
 * Bundle ID : com.oray.sunlogin.controlclient
 * 依赖      : Logos (Theos) + Substrate/ElleKit
 *
 * 设置入口：「我的 → 设置」页底部新增「向日葵增强」二级菜单，
 *          点进去后是一组 UISwitch 开关，配置 NSUserDefaults 持久化。
 * ===================================================================== */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-property-no-attribute"
#pragma clang diagnostic ignored "-Wnullability-completeness"

/* ---------------------------------------------------------------------
 * 编译期类声明（来自被注入 App，仅用于类型检查；统一用完整 @interface
 * 避免 Logos 自动 @class 前向声明导致的 category 编译错误）
 * --------------------------------------------------------------------- */
@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *listTableView;
@end

@interface MainTabBarController : UITabBarController
- (void)sf_refreshTabs;
@end

@interface AccountHostListViewController : UIViewController
@property (nonatomic, strong) UIView *topADView;
@property (nonatomic, strong) NSLayoutConstraint *topADHeightConstraint;
- (void)checkAD;
- (void)showADView;
- (void)hiddenADView;
- (void)resetADView;
- (void)updateADWithAdInfoWithKey:(id)key;
- (void)adInfoLoadedWithKey:(id)key isNeedUpdate:(BOOL)needUpdate;
- (void)pushADWithUrl:(id)url insideJump:(BOOL)insideJump;
- (void)clickADCellClose:(id)sender;
@end

@interface QuickConnectViewController : UIViewController
- (void)checkThdAd;
- (void)refreshAd;
- (void)loadThdAd;
- (void)addAdView:(id)view;
- (void)adInfoLoadedWithKey:(id)key isNeedUpdate:(BOOL)needUpdate;
@end

@interface NewMineViewController : UIViewController
@property (nonatomic, strong) UIButton *messageButton;
@property (nonatomic, strong) NSArray *listDataArray;
@property (nonatomic, strong) UIImageView *vipImageView;
@property (nonatomic, assign) BOOL needUpgrade;
- (void)clickMessage:(id)sender;
- (void)checkMessageCenterInformation;
- (void)setListDataArray:(NSArray *)arr;
- (void)resetDataSource;
- (void)clickMemberButton:(id)sender;
- (void)setNeedUpgrade:(BOOL)upgrade;
- (void)goBtMouseSetting;
- (void)GT_MouseSetting;
- (void)aboutSunlogin;
- (void)contactUs;
- (void)rateSunlogin;
@end

@interface ADFullScreenViewController : UIViewController
- (void)skipBtnDidClicked:(id)sender;
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
@interface ReserveCentralADView : UIView
@end

/* 二级菜单控制器：纯 OC 类（编译期即存在，供设置页直接引用） */
@interface SFSettingsRootViewController : UITableViewController
- (void)sf_switchChanged:(UISwitch *)sender;
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

/* 开关项定义：key / 标题 / 副标题 / 默认值。二级菜单里按此顺序展示。 */
static NSArray<NSDictionary *> *SFOptions(void) {
    static NSArray *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @[
            @{ @"key": @"removeHomeBanner", @"title": @"屏蔽首页横幅广告",
               @"sub": @"主机列表页顶部 / 中心横幅", @"def": @YES },
            @{ @"key": @"removeInfoCenter",  @"title": @"去除信息中心",
               @"sub": @"隐藏「我的」页消息入口与红点检测", @"def": @YES },
            @{ @"key": @"removeVipPromo",   @"title": @"隐藏升级特权引导",
               @"sub": @"「升级版本享受更多特权」入口", @"def": @YES },
            @{ @"key": @"removeWelfare",    @"title": @"隐藏我的福利",
               @"sub": @"「我的」页福利入口", @"def": @YES },
            @{ @"key": @"removeShop",       @"title": @"隐藏硬件商城",
               @"sub": @"「我的」页商城入口", @"def": @YES },
            @{ @"key": @"removeMineMisc",   @"title": @"隐藏其他推广入口",
               @"sub": @"我的兑换 / 订单 / 下载等", @"def": @YES },
            @{ @"key": @"hideBtMouse",      @"title": @"隐藏向日葵蓝牙鼠标",
               @"sub": @"「我的」页蓝牙鼠标入口", @"def": @YES },
            @{ @"key": @"hideAboutHelp",    @"title": @"隐藏关于向日葵与帮助",
               @"sub": @"「我的」页关于/帮助入口", @"def": @YES },
            @{ @"key": @"hideContactUs",    @"title": @"隐藏联系我们",
               @"sub": @"「我的」页联系我们入口", @"def": @YES },
            @{ @"key": @"hideRateEntry",    @"title": @"隐藏向向日葵评分",
               @"sub": @"「我的」页评分入口", @"def": @YES },
            @{ @"key": @"hideDiscover",     @"title": @"隐藏「发现」标签",
               @"sub": @"移除底部发现入口，立即生效", @"def": @YES },
            @{ @"key": @"removeSplash",     @"title": @"屏蔽开屏广告",
               @"sub": @"启动不再等待广告", @"def": @YES },
            @{ @"key": @"removeInsert",     @"title": @"屏蔽插屏广告",
               @"sub": @"切回前台不再弹广告", @"def": @YES },
            @{ @"key": @"removeFeed",       @"title": @"屏蔽信息流广告",
               @"sub": @"发现页/列表页广告位", @"def": @YES },
            @{ @"key": @"blockAdFetch",     @"title": @"阻止广告数据拉取",
               @"sub": @"更彻底，减少联网与耗电", @"def": @YES },
            @{ @"key": @"removeUpdate",     @"title": @"屏蔽版本更新提醒",
               @"sub": @"实验项，关闭更新检测", @"def": @NO },
            @{ @"key": @"removeRate",       @"title": @"屏蔽评分弹窗",
               @"sub": @"点击评分无反应", @"def": @YES },
            @{ @"key": @"hideActivity",     @"title": @"隐藏活动推广位",
               @"sub": @"实验项，「我的」页活动入口", @"def": @NO },
            @{ @"key": @"autoSkipSplash",   @"title": @"开屏广告自动跳过",
               @"sub": @"实验项，出现开屏时自动跳过", @"def": @NO },
        ];
    });
    return options;
}

/* 开关变更后统一广播，让主界面即时刷新（隐藏发现等） */
static void SFNotifyPrefsChanged(NSString *key) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SunflowerPrefsChanged"
                                                        object:key];
}

/* ---------- 「我的」页推广入口过滤 ----------
 * listDataArray 里每个元素平均携带一个功能入口，标题字段可能在
 * title / name / text / itemTitle / menuTitle / desc 等键上。这里把它们
 * 汇成一段文本，再用关键词判断是否属于需要隐藏的推广项。 */
static NSString *SFEntryText(id obj) {
    if (!obj) return @"";
    NSMutableString *text = [NSMutableString string];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        for (id value in [(NSDictionary *)obj allValues]) {
            if ([value isKindOfClass:[NSString class]]) [text appendFormat:@" %@", value];
        }
    } else {
        NSArray *keys = @[@"title", @"name", @"text", @"itemTitle", @"menuTitle",
                          @"titleText", @"desc", @"subTitle", @"itemName"];
        for (NSString *key in keys) {
            @try {
                id value = [obj valueForKey:key];
                if ([value isKindOfClass:[NSString class]]) [text appendFormat:@" %@", value];
            } @catch (NSException *e) { }
        }
    }
    return text;
}

static BOOL SFShouldHideText(NSString *text) {
    if (text.length == 0) return NO;
    /* 关键词 -> 对应开关；命中任意一个即隐藏该项 */
    if (SFBool(@"removeVipPromo", YES) &&
        ([text rangeOfString:@"特权"].location != NSNotFound ||
         [text rangeOfString:@"升级"].location != NSNotFound ||
         [text rangeOfString:@"开通"].location != NSNotFound ||
         [text rangeOfString:@"会员"].location != NSNotFound)) return YES;
    if (SFBool(@"removeWelfare", YES) &&
        [text rangeOfString:@"福利"].location != NSNotFound) return YES;
    if (SFBool(@"removeShop", YES) &&
        ([text rangeOfString:@"商城"].location != NSNotFound ||
         [text rangeOfString:@"商店"].location != NSNotFound)) return YES;
    if (SFBool(@"removeMineMisc", YES) &&
        ([text rangeOfString:@"兑换"].location != NSNotFound ||
         [text rangeOfString:@"订单"].location != NSNotFound ||
         [text rangeOfString:@"下载"].location != NSNotFound)) return YES;
    /* 新增：我的页其他功能入口 */
    if (SFBool(@"hideBtMouse", YES) &&
        ([text rangeOfString:@"蓝牙鼠标"].location != NSNotFound ||
         [text rangeOfString:@"蓝牙"].location != NSNotFound)) return YES;
    if (SFBool(@"hideAboutHelp", YES) &&
        ([text rangeOfString:@"关于向日葵"].location != NSNotFound ||
         [text rangeOfString:@"关于与帮助"].location != NSNotFound ||
         [text rangeOfString:@"帮助与关于"].location != NSNotFound)) return YES;
    if (SFBool(@"hideContactUs", YES) &&
        [text rangeOfString:@"联系我们"].location != NSNotFound) return YES;
    if (SFBool(@"hideRateEntry", YES) &&
        ([text rangeOfString:@"评分"].location != NSNotFound ||
         [text rangeOfString:@"评价一下"].location != NSNotFound)) return YES;
    return NO;
}

static BOOL SFShouldHideEntry(id obj) {
    return SFShouldHideText(SFEntryText(obj));
}

static NSArray *SFFilteredMineEntries(NSArray *arr) {
    if (![arr isKindOfClass:[NSArray class]]) return arr;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:arr.count];
    for (id obj in arr) {
        if (!SFShouldHideEntry(obj)) [result addObject:obj];
    }
    return result;
}

/* 判断某段文案是否属于「升级特权引导」横幅 */
static BOOL SFIsUpgradePromoText(NSString *text) {
    if (text.length == 0) return NO;
    return ([text rangeOfString:@"特权"].location != NSNotFound ||
            [text rangeOfString:@"升级"].location != NSNotFound ||
            [text rangeOfString:@"开通"].location != NSNotFound ||
            [text rangeOfString:@"享受更多"].location != NSNotFound ||
            [text rangeOfString:@"会员"].location != NSNotFound);
}

/* 递归遍历视图树，把文案命中「升级特权」的最近容器整块隐藏，
 * 用于清除服务端动态下发、非 listDataArray 驱动的横幅。 */
static void SFHideUpgradeBannerInView(UIView *root, NSInteger depth) {
    if (!root || depth > 6) return;
    for (UIView *sub in [root subviews]) {
        if (![sub isKindOfClass:[UIView class]]) continue;
        NSString *txt = nil;
        if ([sub isKindOfClass:[UILabel class]]) {
            txt = ((UILabel *)sub).text;
        } else if ([sub isKindOfClass:[UIButton class]]) {
            txt = [(UIButton *)sub titleForState:UIControlStateNormal];
        }
        if (SFIsUpgradePromoText(txt)) {
            UIView *target = sub;
            UIView *parent = sub.superview;
            /* 上溯一层：若父视图不是根视图，隐藏父视图整块更干净 */
            if (parent && parent != root &&
                parent.subviews.count <= 6) target = parent;
            target.hidden = YES;
            continue;
        }
        SFHideUpgradeBannerInView(sub, depth + 1);
    }
}

/* 设置页原始 section 数（hook numberOfSections 时记录） */
static NSInteger SFOrigSections = 0;

/* =====================================================================
 * 2. 二级菜单：SFSettingsRootViewController（纯 OC 类实现）
 * ===================================================================== */
@implementation SFSettingsRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"向日葵增强";
    self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return SFOptions().count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *option = SFOptions()[indexPath.row];
    static NSString *cellID = @"SFToggleCell";
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    UISwitch *sw = (UISwitch *)cell.accessoryView;
    if ([sw isKindOfClass:[UISwitch class]]) {
        [sw setOn:!sw.isOn animated:YES];
        [self sf_switchChanged:sw];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 56.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                         tableView.bounds.size.width, 44.0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16, 6,
                         tableView.bounds.size.width - 32, 32)];
    label.text = @"修改后即时生效 · 配置自动保存";
    label.font = [UIFont systemFontOfSize:12.0];
    label.textColor = [UIColor grayColor];
    label.numberOfLines = 0;
    [header addSubview:label];
    return header;
}

- (void)sf_switchChanged:(UISwitch *)sender {
    NSInteger row = sender.tag;
    NSArray *options = SFOptions();
    if (row < 0 || row >= (NSInteger)options.count) return;
    NSString *key = options[row][@"key"];
    SFSetBool(key, sender.isOn);
    SFNotifyPrefsChanged(key);
    NSLog(@"[SunflowerTweak] set %@ = %@", key, sender.isOn ? @"ON" : @"OFF");
}

@end

/* =====================================================================
 * 3. 设置页：追加一个「向日葵增强」入口，点击进入二级菜单
 * ===================================================================== */
%hook SettingsViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger original = %orig;
    SFOrigSections = original;
    return original + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SFOrigSections) return 1;
    return %orig;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SFOrigSections) {
        static NSString *cellID = @"SFEntryCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellID];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.textLabel.text = @"向日葵增强 · 去广告";
        return cell;
    }
    return %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SFOrigSections) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SFSettingsRootViewController *vc = [[SFSettingsRootViewController alloc]
                                             initWithStyle:UITableViewStyleGrouped];
        if (self.navigationController) {
            [self.navigationController pushViewController:vc animated:YES];
        } else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            [self presentViewController:nav animated:YES completion:nil];
        }
        return;
    }
    %orig;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SFOrigSections) return 50.0;
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
        label.text = @"增强插件 (TrollStore)";
        label.font = [UIFont boldSystemFontOfSize:13.0];
        label.textColor = [UIColor grayColor];
        [header addSubview:label];
        return header;
    }
    return %orig;
}

%end

/* =====================================================================
 * 4. 主 TabBar：隐藏「发现」标签 + 响应设置变更
 * ===================================================================== */
%hook MainTabBarController

- (void)viewDidLoad {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sf_refreshTabs)
                                                 name:@"SunflowerPrefsChanged"
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
                                                    name:@"SunflowerPrefsChanged"
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

/* TabBar 自身携带的广告兜底 */
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
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}
- (void)pushReserveADWithUrl:(id)url insideJump:(BOOL)insideJump {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

/* 版本更新检测（可选关闭） */
- (void)checkVersionAvailabilityWithFinish:(id)finish {
    if (SFBool(@"removeUpdate", NO)) return;
    %orig;
}

%end

/* =====================================================================
 * 5. 首页主机列表：屏蔽顶部 / 中心横幅广告（本次新增的关键 hook）
 * ===================================================================== */
%hook AccountHostListViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if (!SFBool(@"removeHomeBanner", YES)) return;
    /* 收起顶部横幅并把高度约束归零，确保 tableView 不留空白 */
    @try {
        UIView *topView = [self valueForKey:@"topADView"];
        if ([topView isKindOfClass:[UIView class]]) topView.hidden = YES;
        NSLayoutConstraint *hc = [self valueForKey:@"topADHeightConstraint"];
        if ([hc isKindOfClass:[NSLayoutConstraint class]]) hc.constant = 0.0;
    } @catch (NSException *e) { }
    /* 兜底：隐藏 ids 里的广告视图 */
    for (NSString *key in @[@"adView", @"listADView", @"bannerView"]) {
        @try {
            id v = [self valueForKey:key];
            if ([v isKindOfClass:[UIView class]]) ((UIView *)v).hidden = YES;
        } @catch (NSException *e) { }
    }
}

- (void)checkAD {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

- (void)updateADWithAdInfoWithKey:(id)key {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

- (void)adInfoLoadedWithKey:(id)key isNeedUpdate:(BOOL)needUpdate {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

- (void)pushADWithUrl:(id)url insideJump:(BOOL)insideJump {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

- (void)showADView {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

- (void)clickADCellClose:(id)sender {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

%end

/* =====================================================================
 * 6. 快速连接页：屏蔽第三方广告位（本次新增）
 * ===================================================================== */
%hook QuickConnectViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if (!SFBool(@"removeHomeBanner", YES)) return;
    @try {
        id v = [self valueForKey:@"adView"];
        if ([v isKindOfClass:[UIView class]]) ((UIView *)v).hidden = YES;
    } @catch (NSException *e) { }
}

- (void)checkThdAd {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}
- (void)refreshAd {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}
- (void)loadThdAd {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}
- (void)addAdView:(id)view {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}
- (void)adInfoLoadedWithKey:(id)key isNeedUpdate:(BOOL)needUpdate {
    if (SFBool(@"removeHomeBanner", YES)) return;
    %orig;
}

%end

/* 首页中心预留广告视图：强制隐藏 */
%hook ReserveCentralADView
- (void)layoutSubviews {
    %orig;
    if (SFBool(@"removeHomeBanner", YES)) self.hidden = YES;
}
%end

/* =====================================================================
 * 7. 开屏广告：Google / 微博(WindMill) / Taku 三条链路
 * ===================================================================== */
%hook GADManager

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
 * 8. 插屏广告
 * ===================================================================== */
%hook InsertAdManager
- (void)didBecomeActive:(id)notification {
    if (SFBool(@"removeInsert", YES)) return;
    %orig;
}
%end

/* =====================================================================
 * 9. 发现页信息流广告
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
 * 10. 广告数据拉取（深度去广告）
 * ===================================================================== */
%hook ADInfoManager
- (void)updateStartupAD             { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateHotStartupAD          { if (SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDeviceListAD          { if (SFBool(@"removeHomeBanner", YES) || SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDeviceTopAD           { if (SFBool(@"removeHomeBanner", YES) || SFBool(@"blockAdFetch", YES)) return; %orig; }
- (void)updateDeviceReserveAD       { if (SFBool(@"removeHomeBanner", YES) || SFBool(@"blockAdFetch", YES)) return; %orig; }
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
 * 11. 「我的」页：信息中心 / 评分 / 活动推广位
 * ===================================================================== */
%hook NewMineViewController

- (void)viewDidLayoutSubviews {
    %orig;
    /* 隐藏信息中心入口（消息按钮） */
    if (SFBool(@"removeInfoCenter", YES)) {
        @try {
            id btn = [self valueForKey:@"messageButton"];
            if ([btn isKindOfClass:[UIView class]]) ((UIView *)btn).hidden = YES;
        } @catch (NSException *e) { }
    }
    /* 隐藏升级特权引导：VIP 标识 + 动态下发的横幅（递归清理头部视图） */
    if (SFBool(@"removeVipPromo", YES)) {
        @try {
            UIImageView *vip = [self valueForKey:@"vipImageView"];
            if ([vip isKindOfClass:[UIView class]]) vip.hidden = YES;
        } @catch (NSException *e) { }
        @try {
            UIView *header = [self valueForKey:@"headerInfoView"];
            if ([header isKindOfClass:[UIView class]]) {
                SFHideUpgradeBannerInView(header, 0);
            }
        } @catch (NSException *e) { }
        /* 遍历 tableView 的 tableHeaderView / header 视图 */
        @try {
            id tv = [self valueForKey:@"listTableView"];
            if ([tv isKindOfClass:[UITableView class]]) {
                UIView *th = ((UITableView *)tv).tableHeaderView;
                if (th) SFHideUpgradeBannerInView(th, 0);
            }
        } @catch (NSException *e) { }
    }
    /* 隐藏活动推广位 */
    if (SFBool(@"hideActivity", NO)) {
        NSArray *keys = @[@"activityLineView", @"activityBgView1", @"activityBgView3",
                          @"activityLabel_1", @"activityLabel_2", @"activityLabel_3"];
        for (NSString *key in keys) {
            @try {
                id view = [self valueForKey:key];
                if ([view isKindOfClass:[UIView class]]) ((UIView *)view).hidden = YES;
            } @catch (NSException *e) { }
        }
    }
    /* 兜底：遍历 tableView 可见 cell，把命中关键词的整行直接隐藏 */
    if (SFBool(@"removeVipPromo", YES) || SFBool(@"removeWelfare", YES) ||
        SFBool(@"removeShop", YES) || SFBool(@"removeMineMisc", YES) ||
        SFBool(@"hideBtMouse", YES) || SFBool(@"hideAboutHelp", YES) ||
        SFBool(@"hideContactUs", YES) || SFBool(@"hideRateEntry", YES)) {
        @try {
            id tv = [self valueForKey:@"listTableView"];
            if ([tv isKindOfClass:[UITableView class]]) {
                for (UITableViewCell *cell in [(UITableView *)tv visibleCells]) {
                    NSString *txt = cell.textLabel.text ?: @"";
                    if (cell.detailTextLabel.text) txt = [txt stringByAppendingString:cell.detailTextLabel.text];
                    if (SFShouldHideText(txt)) cell.hidden = YES;
                }
            }
        } @catch (NSException *e) { }
    }
}

/* 数据源过滤：从源头剔除推广入口（最彻底，行数同步减少） */
- (void)setListDataArray:(NSArray *)arr {
    NSArray *filtered = SFFilteredMineEntries(arr);
    %orig(filtered);
}

- (void)resetDataSource {
    %orig;
    @try {
        NSArray *cur = [self valueForKey:@"listDataArray"];
        NSArray *filtered = SFFilteredMineEntries(cur);
        if (filtered.count != cur.count) {
            [self setValue:filtered forKey:@"listDataArray"];
        }
    } @catch (NSException *e) { }
}

/* 拦截点击信息中心，防止从其他入口跳转 */
- (void)clickMessage:(id)sender {
    if (SFBool(@"removeInfoCenter", YES)) return;
    %orig;
}

/* 屏蔽红点/未读检测，避免服务端持续拉取 */
- (void)checkMessageCenterInformation {
    if (SFBool(@"removeInfoCenter", YES)) return;
    %orig;
}

/* 拦截升级特权 / 福利 / 商城等点击，防止残留入口跳转 */
- (void)clickMemberButton:(id)sender {
    if (SFBool(@"removeVipPromo", YES)) return;
    %orig;
}
- (void)goWelfare {
    if (SFBool(@"removeWelfare", YES)) return;
    %orig;
}
- (void)goToHardwareStore {
    if (SFBool(@"removeShop", YES)) return;
    %orig;
}
- (void)goMyExchange {
    if (SFBool(@"removeMineMisc", YES)) return;
    %orig;
}
- (void)goToMyOrder {
    if (SFBool(@"removeMineMisc", YES)) return;
    %orig;
}
- (void)goMineDownload {
    if (SFBool(@"removeMineMisc", YES)) return;
    %orig;
}

/* 从源头阻断「升级特权」横幅：needUpgrade=NO，则不会布置引导视图 */
- (void)setNeedUpgrade:(BOOL)upgrade {
    if (SFBool(@"removeVipPromo", YES)) {
        %orig(NO);
        return;
    }
    %orig(upgrade);
}

/* 新增入口的点击拦截 */
- (void)goBtMouseSetting {
    if (SFBool(@"hideBtMouse", YES)) return;
    %orig;
}
- (void)GT_MouseSetting {
    if (SFBool(@"hideBtMouse", YES)) return;
    %orig;
}
- (void)aboutSunlogin {
    if (SFBool(@"hideAboutHelp", YES)) return;
    %orig;
}
- (void)contactUs {
    if (SFBool(@"hideContactUs", YES)) return;
    %orig;
}

/* 评分入口：hideRateEntry 隐藏入口；removeRate 保留原「屏蔽评分弹窗」语义 */
- (void)rateSunlogin {
    if (SFBool(@"hideRateEntry", YES) || SFBool(@"removeRate", YES)) return;
    %orig;
}

%end

/* =====================================================================
 * 12. 构造入口
 * ===================================================================== */
%ctor {
    NSLog(@"[SunflowerTweak] loaded. bundle=%@  ver=%@",
          [[NSBundle mainBundle] bundleIdentifier],
          [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
}

#pragma clang diagnostic pop
