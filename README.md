Script Sammlung zum Erstellen des Betriebssystem Images für die 'xMZ-Mod-Touch'-Platform

# Vorbereitungen
Diese Skripte sind dafür vorgesehen auf einem Debian System gestartet zu werden.
Ich empfehle ausdrücklich ein Debian `sid` für diesen Zweck zu verwenden.

```bash
apt-get install qemu-user-static binfmt-support
apt-get install systemd-container
```


# Reihenfolge und Funktionsbeschreibung

## 01.build_systemd-nspawn_containers.sh


### 02.build_development_files.sh

This script must be called into the development systemd-nspawn container.
The debian OS must be jessie.
It builds needed tools (sunxi), the linux kernel and the xMZ-Mod-Touch-GUI.
Afterwards this files are packed into an tar archive.

### 03.setup_production_container.sh


### 10.stage1-create_basic_image.sh
### 11.stage2-bootloader_kernel_and_modules.sh
### 12.stage3.sh


# Wiki

There is a github.com wiki for this repository. To get it run this command
into the repo root

    git submodule init
    git submodule update


# Source code

- https://github.com/zzeroo/xMZ-Mod-Touch-Image.git
- https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git
