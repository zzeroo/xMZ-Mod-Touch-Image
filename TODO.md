# OhMyZsh Update deaktivieren

Obwohl die entsprechenden Einträge in der .zshrc vorhanden sind wird beim erstem login nach dem autoupdate gefragt.
Danach ist das Auto update deaktiviert.

Ermittele die Zusammenhänge und finde eine Lösung.

# Kernel

# New flow
## Maybe one script (nice if it where in rust :)

* We only need one template file system


Basic (template) filesystem exists?
          |
          |--no--> debootstrap ...
          |
          | yes
          |/
  Linux kernel exists?
          |
          |--no--> git clone ...
          |
          /yes
    Build kernel
          |
          |/
  U-boot exist?
          |
          |--no--> git clone ...
          |
          |/yes
    Build u-boot
          |
          |/


