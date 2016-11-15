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
Dieses Script installiert mit `debootstrap` ein Root Dateisystem. Dies ist die Basis aller späteren Scripte.

### 02.setup_OS.sh
In diesem Script werden die Betriebssystem Komponenten wie Netzwerk, SSH, Timezonen und locales eingerichtet.

### 03.setup_production_container.sh


### 10.stage1-create_basic_image.sh
### 11.stage2-bootloader_kernel_and_modules.sh
### 12.stage3.sh

# Beispiel Aufrufe der Scripte
```bash
./01* -v && \
./02* -v && \
./03* -v && \
./04* -v && \
./10* -v && \
./11* -v && \
./12* -v
```

# Wiki

There is a github.com wiki for this repository. To get it run this command
into the repo root

    git submodule init
    git submodule update


# Source code

- https://github.com/zzeroo/xMZ-Mod-Touch-Image.git
- https://github.com/zzeroo/xMZ-Mod-Touch-GUI.git
