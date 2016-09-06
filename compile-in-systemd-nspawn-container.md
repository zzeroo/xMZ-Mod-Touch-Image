# Compilation in systemd-nspawn container
## Debian sid, dysfunctional

| Failed:
| Cairo-rs kann nicht kompelliert werden.

```bash
#!/bin/bash
# Exit on error or variable unset
set -o errexit -o nounset

cat <<EOF> /etc/apt/sources.list
deb http://ftp.de.debian.org/debian sid main contrib non-free
EOF

apt-get update

apt-get install -yy curl git vim-scripts
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
source .profile

apt-get install -yy libgtk-3-dev

# Software auschecken
cd
git clone https://github.com/Kliemann-Service-GmbH/xMZ-Mod-Touch-Software.git
cd xMZ-Mod-Touch-Software
git submodule init
git submodule update
# GUI bilden
cd
cd xMZ-Mod-Touch-Software/xMZ-Mod-Touch-GUI
# Build starten
cargo build --release
```

## Debian jessie, dysfunctional

| Fehlerhaft:

```bash
#!/bin/bash
# Exit on error or variable unset
set -o errexit -o nounset

dpkg --add-architecture armhf
apt-get update

apt-get install -yy curl git
curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
source .profile
rustup target add armv7-unknown-linux-gnueabihf

apt-get install -yy gcc-arm-none-eabi-gcc

# apt-get install -yy libgtk-3-dev
apt-get install -yy libgtk-3-dev:armhf
# Software auschecken
cd
git clone https://github.com/Kliemann-Service-GmbH/xMZ-Mod-Touch-Software.git
cd xMZ-Mod-Touch-Software
git submodule init
git submodule update
# GUI bilden
cd
cd xMZ-Mod-Touch-Software/xMZ-Mod-Touch-GUI
mkdir -p .cargo
cat <<EOF > .cargo/config
[target.armv7-unknown-linux-gnueabihf]
linker = "arm-none-eabi-gcc"
EOF

# PKG_CONFIG_ALLOW_CROSS=1 cargo build --release --target=armv7-unknown-linux-gnueabihf
cargo build --release --target=armv7-unknown-linux-gnueabihf



```
