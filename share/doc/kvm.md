
```bash
export KERNEL="/usr/src/linux/arch/arm/boot/zImage"
export DTB="/usr/src/linux/arch/arm/boot/dts/sun7i-a20-bananapro.dtb"
export IMAGE="/home/smueller/src/xMZ-Mod-Touch-Image/xmz-sid-baseimage.img"
sudo qemu-system-arm -m 1G -M vexpress-a15 -cpu host -kernel ${KERNEL} -dtb ${DTB} -append "root=/dev/vda console=ttyAMA0 rootwait" -drive if=none,file=${IMAGE},id=xmz-sid-baseimage -raw -device virtio-blk-device,drive=xmz-sid-baseimage -net nic -net user -monitor null -serial stdio -nographic
```

Quelle: http://blog.flexvdi.com/2014/07/24/configurar-virtualizacion-kvm-sobre-arm-allwinner-a20/
