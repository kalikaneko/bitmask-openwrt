include $(TOPDIR)/rules.mk

PKG_NAME:=bitmask-vpn
PKG_VERSION:=0.0.1
PKG_RELEASE:=4

PKG_LICENSE:=GPL-3.0
PKG_MAINTAINER:=Kali Kaneko <kali@leap.se>

#PKG_BUILD_DIR:=$(BUILD_DIR)/bitmask-$(PKG_VERSION)
#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=https://sindominio.net/~kali/bitmask/$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_HASH:=274667884fa1f240334279bcf4af37c33f9bcf01086fc6705fe4f98726e9eafe

HOST_BUILD_DEPENDS:=nim/host

include $(INCLUDE_DIR)/package.mk

define Package/bitmask-vpn
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Client for RiseupVPN and other leap providers
  URL:=https://leap.se
  SUBMENU:=VPN
  PROVIDES:=bitmaskd
  DEPENDS:=+openvpn-mbedtls +curl +kmod-tun
endef

define Package/bitmask-vpn/description
  Configure OpenVPN to use RiseupVPN or other compatible LEAP-VPN providers.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

# just to make sure we don't pass something nim won't recognize
ifeq ($(ARCH),mips)
	NIM_TARGET:=mips
endif
ifeq ($(ARCH),mipsel)
	NIM_TARGET:=mipsel
endif

# Package preparation; create the build directory and copy the source code.
# The last command is necessary to ensure our preparation instructions remain compatible with the patching system.
define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	cp -r providers $(PKG_BUILD_DIR)
	cp -r scripts $(PKG_BUILD_DIR)
	$(Build/Patch)
endef

define Build/Compile
	nim -d:release --threads:on --opt=size --cpu:$(NIM_TARGET) --os:linux --outDir:$(PKG_BUILD_DIR) c src/bitmask.nim
endef
# upx --brute $(PKG_BUILD_DIR)/bitmaskd
# upx==3.93 is tested, higher versions seem to inutilize the binary https://github.com/upx/upx/issues/87

define Package/bitmask-vpn/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/bitmask/scripts
	$(INSTALL_DIR) $(1)/etc/rc.button/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bitmaskd $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/bitmask
	$(CP) -r $(PKG_BUILD_DIR)/providers $(1)/etc/bitmask
	$(CP) -r $(PKG_BUILD_DIR)/scripts $(1)/etc/bitmask
endef


$(eval $(call BuildPackage,bitmask-vpn))
