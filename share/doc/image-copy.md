

```
sudo dd if=/dev/sde |pv| dd of=xmz-copy-`date +%F-%N`.img bs=1024 count=$[4000*1024] iflag=fullblock
```
