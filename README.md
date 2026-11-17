# SunflowerTweak — 向日葵 15.5.10 去广告 / 功能增强插件

适用于 **TrollStore（巨魔）** 注入的 dylib 插件。目标 App：向日葵远程控制
`com.oray.sunlogin.controlclient`（已针对 15.5.10 / 版本 15.5.10.55663 逆向适配）。

---

## 一、功能

插件入口在 App 内的 **「我的」→「设置」** 页面最底部，样式为一个新的分组，
里面全部是 `UISwitch` 开关，改动即时生效并持久化：

| 开关 | 默认 | 作用 |
| --- | --- | --- |
| 隐藏「发现」标签 | 开 | 从底部 TabBar 移除发现页 |
| 屏蔽开屏广告 | 开 | 拦截 AdMob / 微博 / Taku 三条开屏链路 |
| 屏蔽插屏广告 | 开 | 阻止切回前台时弹出的插屏 |
| 屏蔽信息流广告 | 开 | 发现页 / 列表页广告位 |
| 阻止广告数据拉取 | 开 | 从源头阻止各广告位请求素材（更省流量/电量） |
| 屏蔽版本更新提醒 | 关 | 实验项，关闭更新检测 |
| 屏蔽评分弹窗 | 关 | 点击评分不再跳转 |
| 隐藏活动推广位 | 关 | 实验项，「我的」页活动入口 |
| 开屏广告自动跳过 | 关 | 实验项，开屏出现时自动点击跳过 |

> 说明：源码里另做了免广告启动的判断（GADManager finished 回调主动触发），
> 避免屏蔽开屏后卡在启动动画。

---

## 二、逆向依据（适配点）

二进制 `controlclient` **未加密（cryptid=0）**，arm64，最低 iOS 10.0。
关键类与方法（取自 Objective-C 元数据）：

- `MainTabBarController`：底部 TabBar，`pageSignArr` 管理页面标识；
  `checkAD` / `updateADWithAdInfo:` / `pushReserveADWithUrl:insideJump:` 为广告逻辑
- `NewDiscoverViewController`：发现页，`refreshAd` / `getInsertAd` / `updateADWithAdsInfoKey:`
- `SettingsViewController`：设置页，`numberOfSectionsInTableView:` 等数据源方法用于追加开关区
- `GADManager`：`showAdIfAvailableWithRootViewController:scene:shownHandler:clickHandler:finishedHandler:`
  （AdMob 开屏）
- `WMADManager`（微博）、`TakuADManager`（Taku）开屏
- `ADInfoManager`：`updateStartupAD` 等 ~14 个广告位拉取方法
- `InsertAdManager`：`didBecomeActive:` 插屏触发点
- `ADFullScreenViewController`：`skipBtnDidClicked:` 开屏跳过按钮
- `NewMineViewController`：`rateSunlogin` 评分弹窗

二进制内嵌广告 SDK：AnyThinkSDK / GDTMobSDK（广点通）/ SmartdigimktSDK /
Google Mobile Ads / IronSource / 穿山甲(CSJ) / WindMill(微博) 等。

---

## 三、编译

本机为 Windows，无 iOS SDK / Theos，**无法在此直接编译出 dylib**。
请在 macOS（或 Linux 装 Theos）上操作：

```bash
# 1. 安装 Theos（若未安装）
bash <(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)

# 2. 进入工程目录
cd SunflowerTweak

# 3. 编译
make clean && make package

# 产物: .theos/obj/SunflowerTweak.dylib  (根目录也会复制一份)
```

> 如果 Theos 不支持 `rootless` scheme，删掉 Makefile 里的
> `THEOS_PACKAGE_SCHEME = rootless` 一行再编译；TrollStore 两种布局都可用。

---

## 四、注入 IPA（TrollStore）

需要工具：`insert_dylib`（`brew install insert_dylib` 或源码编译）。

```bash
# 把编译好的 SunflowerTweak.dylib 放到本目录后：
chmod +x inject.sh
./inject.sh "/path/to/向日葵-15.5.10.ipa"

# 生成 SunflowerTweak_injected.ipa，用 TrollStore 安装即可
```

手动注入流程等价：

1. 解压 IPA，进入 `Payload/controlclient.app/`
2. 把 `SunflowerTweak.dylib` 复制进去
3. `insert_dylib --inplace --weak @executable_path/SunflowerTweak.dylib controlclient`
4. 重新打包成 IPA，TrollStore 安装
5. （可选）`ldid -S controlclient` 去掉签名冲突

---

## 五、风险与提示

- 实验项（更新/活动/自动跳过）默认关闭，如需开启请自行评估。
- 「隐藏发现」通过移除 TabBar 控制器实现，若服务端下发跳转发现页的推送，
  可能依旧能打开该页面（只是底部入口隐藏）。
- 若屏蔽开屏后出现启动白屏卡住，进入设置把「屏蔽开屏广告」关掉即可恢复。
- 卸载：TrollStore 里重装原版 IPA，或删除注入的 dylib 后重装。
- 本插件仅用于个人学习 / 去广告，请勿用于商业用途。

---

## 六、文件清单

- `Tweak.xm` — 插件全部逻辑（Logos 语法）
- `Makefile` — Theos 编译配置
- `control` / `SunflowerTweak.plist` — 包信息与注入 Target
- `inject.sh` — IPA 注入脚本
- `README.md` — 本文档
