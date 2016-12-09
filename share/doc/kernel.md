
## Kernel Konfiguration aufrufen
Es ist wichtig das die Cross Compile Umgebung und die ARCH Architektur dem make
Befehl mit übergeben werden. Sonnst wird die Configuration des falschen Kernels bearbeitet.
Einfach nur `make menuconfig` ruft die Kernel Konfiguration des Host Systems auf,
`make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- menuconfig` hingegen die
Kernel Konfiguration des arm Prozessors.

```bash
cp ./arch/arm/configs/sunxi_defconfig ./arch/arm/configs/sunxi_xmz_defconfig
```

```bash
cat <<EOF >> ./arch/arm/configs/sunxi_xmz_defconfig
CONFIG_BTRFS_FS=y
CONFIG_INPUT_MOUSEDEV=y
CONFIG_TOUCHSCREEN_EDT_FT5X06=m
WIRELESS=y
CONFIG_CFG80211=m
CONFIG_MAC80211=m
CONFIG_MAC80211_LEDS=y
CONFIG_WLAN=y
CONFIG_BRCMFMAC=y
CONFIG_USB_SERIAL=m
CONFIG_USB_SERIAL_GENERIC=y
CONFIG_USB_SERIAL_FTDI_SIO=m
EOF
```
```bash
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- sunxi_xmz_defconfig
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- menuconfig
```

## Kernel bauen
```bash
make -j$[`nproc`+1] ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- zImage modules dtbs
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- INSTALL_MOD_PATH=output modules_install
```

## WLAN Firmware installieren
```bash
cd /usr/src/linux
mkdir -p output/lib/firmware/brcm/
wget -O output/lib/firmware/brcm/brcmfmac43362-sdio.txt https://raw.githubusercontent.com/zzeroo/xMZ-Mod-Touch-Image/master/share/brcmfmac43362-sdio.txt
```

## Kernel und DeviceTree in die 1. Partition kopieren
```bash
sudo umount /dev/sde{1,2}
sudo mount /dev/sde1 /mnt/disk
sudo cp -v /usr/src/linux/arch/arm/boot/zImage /mnt/disk/zImage
sudo cp -v /usr/src/linux/arch/arm/boot/dts/sun7i-a20-bananapro.dtb /mnt/disk/sun7i-a20-bananapro.dtb
```

## Kernelmodule in die 2. Partition kopieren
```bash
sudo umount /dev/sde{1,2}
sudo mount /dev/sde2 /mnt/disk
sudo rm /mnt/disk/lib/modules/* -rf
sudo cp -rv /usr/src/linux/output/lib /mnt/disk
sudo umount /mnt/disk
```
