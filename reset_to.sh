#!/bin/bash
# In diesem Script sind alle Tasks zusammengefsst die den eigenen Software Stack bilden.
#
# Exit on error or variable unset
set -o errexit


# Checke Parameter
if [ $# -ne 1 ]; then
  echo -e "\nFehler: Falscher Aufruf\n"
  echo -e "\t$0 NAME_LETZTES_ERFOLGREICHES_SCRIPT\n"
  exit 1
fi


# Alles OK Start des Scripts
LAST_STATE="/var/lib/container/sid_armhf-`basename -s.sh $1`"
WORK_DIR="/var/lib/container/sid_armhf"

# Lösche aktuelles Arbeitsverzeichnis
if [ -d ${LAST_STATE} ]; then
  sudo btrfs subvolume delete ${WORK_DIR}
  sudo btrfs subvolume snapshot ${LAST_STATE} ${WORK_DIR}
else
  echo -e "\nFehler: ${LAST_STATE} existiert nicht!\n"
  echo -e "Verfügbare Container:"
  ls -al /var/lib/container
  exit 2
fi
