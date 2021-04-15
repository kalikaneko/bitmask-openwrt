all: build

build:
	nim release.nims
build-mips:
	nim compile -d:release -d:usestd --threads:on --opt:size --cpu:mips --os:linux --out:"bitmaskd" --stackTrace:on --lineTrace:on bitmask.nim
build-mipsel:
	nim compile -d:release --threads:on --opt:size --cpu:mipsel --os:linux --out:"bitmaskd" bitmask.nim
pack:
	upx bitmaskd
deps:
	nimble install -y argparse syslog prologue
dev:
	apt install openvpn
test:
	sudo pkill bitmask-vpn || true && sudo rm -f /tmp/bitmask.pid && sudo ./bitmaskd start-server
test-MT300N: build-mipsel #pack
	scp bitmaskd root@192.168.1.1:./
test-AR750: build-mips #pack
	scp bitmaskd root@192.168.8.1:./
