# U-boot bauen

```bash
cd
git clone git://git.denx.de/u-boot.git
cd u-bootcat <<-EOF >>configs/Bananapro_defconfig
CONFIG_VIDEO_LCD_MODE="x:1024,y:600,depth:24,pclk_khz:55000,le:100,ri:170,up:10,lo:15,hs:50,vs:10,sync:3,vmode:0"
CONFIG_VIDEO_LCD_PANEL_LVDS=y
CONFIG_VIDEO_LCD_POWER="PH12"
CONFIG_VIDEO_LCD_BL_EN="PH8"
CONFIG_VIDEO_LCD_BL_PWM="PB2"
CONFIG_VIDEO_LCD_BL_PWM_ACTIVE_LOW=n
CONFIG_BOOTDELAY=0
EOF
make ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf- Bananapro_defconfig
make -j$[`nproc`+1] ARCH=arm CROSS_COMPILE=/usr/bin/arm-linux-gnueabihf-
```

# U-boot auf SD Karte updaten

```bash
sudo umount /dev/sdd{1,2}
sudo dd if=/dev/zero of=/dev/sdd bs=1k count=1023 seek=1
sudo dd if=/usr/src/u-boot/u-boot-sunxi-with-spl.bin of=/dev/sdd bs=1024 seek=8
```

# Bildschirm über sysfs ein und aus schalten

```bash
echo 34 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio34/direction
# ein
echo 1 > /sys/class/gpio/gpio34/value
# aus
echo 0 > /sys/class/gpio/gpio34/value
```
