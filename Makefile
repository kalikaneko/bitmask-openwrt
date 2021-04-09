include $(TOPDIR)/rules.mk

PKG_NAME:=bitmask-vpn
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

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
  TITLE:=BitmaskVPN
  URL:=https://leap.se
  SUBMENU:=VPN
  PROVIDES:=bitmask
  DEPENDS:=+openvpn +curl
endef

# NOPE +libopenssl 
# TODO +iptables

define Package/bitmask-vpn/description
  Configure OpenVPN to use RiseupVPN or other compatible LEAP-VPN providers.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

# FIXME get architecture from env var

define Build/Compile
	nim -d:release --threads:on --opt=size --cpu:mipsel --os:linux --outDir:$(PKG_BUILD_DIR) c src/bitmask.nim
	upx $(PKG_BUILD_DIR)/bitmaskd
endef

define Package/bitmask-vpn/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bitmaskd $(1)/usr/bin/
endef


$(eval $(call BuildPackage,bitmask-vpn))
