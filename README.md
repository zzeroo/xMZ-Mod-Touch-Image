

# Docker
## Base image

Das Base image wird mit dem Script ./create-base-image.sh erstellt.

Folgende Befehle importieren das Base Image in docker:

```
export BASEIMAGE=base-image-jessie
sudo tar -C $BASEIMAGE -c . | docker import - $BASEIMAGE
```

Folgender Befehl testet das Base Image

```
docker run --rm $BASEIMAGE cat /etc/issue
```


##Create Image from base-image

```
export base_image=base-image-sid
export image=stage1-image.img
export card=/dev/loop
export part="1"
sudo losetup /dev/loop${part}0 ${image}
sudo losetup --offset $[2048 * 512] ${card}${part}1 ${image}
sudo losetup --offset $[43008 * 512] ${card}${part}2 ${image}
export mnt=/tmp/disk${part}
[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}
sudo mount ${card}${part}2 ${mnt}
sudo rsync -av ${base_image}/* ${mnt}
sudo umount ${mnt}
sudo losetup -d ${card}${part}{0,1,2}
mv stage1-image.img stage2-image.img
```

```
# umount /dev/sdd{1,2}
export image=stage2-image.img
dd if=${image} | pv | sudo dd of=/dev/sdc bs=1M
```

```
```

##Export Docker Container auf SD Card

```
export image=docker-image.img
export card=/dev/loop
export part="1"
sudo losetup /dev/loop${part}0 ${image}
sudo losetup --offset $[2048 * 512] ${card}${part}1 ${image}
sudo losetup --offset $[43008 * 512] ${card}${part}2 ${image}
export mnt=/tmp/disk${part}
[[ ! -d ${mnt}  ]] && sudo mkdir ${mnt}
sudo mount ${card}${part}2 ${mnt}
```

```
docker run base-image-jessie --name=export_container true
docker export export_continer | sudo tar -xv -C ${mnt}
sudo umount ${mnt}
sudo losetup -d /dev/loop${part}{0,1,2}
```


