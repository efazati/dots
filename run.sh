#!/bin/bash

# Config folder
ln -s $(realpath ./i3) ~/.config/
ln -s $(realpath ./polybar) ~/.config/
ln -s $(realpath ./rofi) ~/.config/
ln -s $(realpath ./dunst) ~/.config/
ln -s $(realpath ./tmux) ~/.tmux

ln -s $(realpath ./Xdefaults) ~/.Xdefaults
ln -s $(realpath ./Xresources) ~/.Xresources
ln -s $(realpath ./zshrc) ~/.zshrc
ln -s $(realpath ./vimrc) ~/.vimrc
ln -s $(realpath ./tmux.conf) ~/.tmux.conf

mkdir -p ~/bin/screen  
ln -s /home/efazati/.screenlayout/1mon.sh ~/bin/screen/default.sh
