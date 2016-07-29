#!/bin/bash
# Installation von oh-my-zsh auf bekannter Platform in genau definierter Umgebung.
#
# Dieses Script hat kein Color Output noch prüft es seine Umgebung. Es installiert
# lediglich oh-my-zsh.

set -e

ZSH=~/.oh-my-zsh

env git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $ZSH
