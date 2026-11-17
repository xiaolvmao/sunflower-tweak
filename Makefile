# ===== 向日葵增强插件 (TrollStore dylib) =====
# 目标: com.oray.sunlogin.controlclient 15.5.10
# 编译环境: Theos (https://theos.dev) + iOS 14+ SDK

# TrollStore 需要 rootless 布局; 若你的 Theos 不支持 rootless, 见 README
THEOS_PACKAGE_SCHEME = rootless

TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SunflowerTweak

# 源文件
SunflowerTweak_FILES = Tweak.xm

# 编译标志
SunflowerTweak_CFLAGS = -fobjc-arc -Wno-unused-parameter -Wno-deprecated-declarations

# 需要的系统框架
SunflowerTweak_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

# 编译完成后把 dylib 复制到工程根目录, 方便取用
after-stage::
	@cp -f .theos/obj/$(TWEAK_NAME).dylib ./$(TWEAK_NAME).dylib 2>/dev/null || true
	@echo "--------------------------------------------------"
	@echo "  Build done: ./$(TWEAK_NAME).dylib"
	@echo "  Bundle ID : com.oray.sunlogin.controlclient"
	@echo "--------------------------------------------------"
