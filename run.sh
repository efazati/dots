#!/bin/bash

# Config folder
ln -s $(realpath ./i3) ~/.config/
ln -s $(realpath ./polybar) ~/.config/
ln -s $(realpath ./rofi) ~/.config/
ln -s $(realpath ./dunst) ~/.config/
ln -s $(realpath ./tmux) ~/.tmux
ln -s $(realpath ./images) ~/images

ln -s $(realpath ./Xdefaults) ~/.Xdefaults
ln -s $(realpath ./Xresources) ~/.Xresources
ln -s $(realpath ./zshrc) ~/.zshrc
ln -s $(realpath ./vimrc) ~/.vimrc
ln -s $(realpath ./tmux.conf) ~/.tmux.conf

mkdir -p ~/bin/screen  
ln -s /home/efazati/.screenlayout/1mon.sh ~/bin/screen/default.sh

sudo apt install -y fonts-font-awesome
sudo apt install zsh-autosuggestions zsh-syntax-highlighting zsh


git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $ZSH_CUSTOM/plugins/zsh-autocomplete

sudo chmod 777 /etc/wireguard 

# INSERT_YOUR_USERNAME ALL = (root) NOPASSWD: /usr/bin/wg-quick
# /etc/sudoers.d/wiregaurd
