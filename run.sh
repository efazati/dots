#!/bin/bash

sudo apt update

sudo apt install -y \
    i3 \
    curl \
    zsh \
    feh \
    git \
    rxvt-unicode \
    htop \
    polybar \
    rofi \
    tmux \
    fonts-font-awesome \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    thunar \
    arandr \
    lxappearance \
    vim \
    bat \
    autojump \
    xfce4-clipman \
    xfce4-screenshooter \
    xclip \
    x11vnc \
    wireguard \
    wireguard-tools \
    vagrant \
    tigervnc-viewer \
    samba \
    samba-vfs-modules \
    rxvt-unicode \
    git \
    remmina \
    psensor \
    zenity \
    zip \
    suckless-tools \
    hwinfo \
    htop \
    fonts-noto-color-emoji \
    fonts-noto-core \
    flatpak \
    evince \
    blueman \
    bluez \
    awscli \
    pavucontrol 

sudo chsh efazati -s /bin/zsh

mkdir -p $HOME/.fonts/
cp ./fonts/monaco.ttf $HOME/.fonts/
fc-cache -fv

OH_ZSH_PATH="$HOME/.oh-my-zsh"
ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Config folder
ln -s $(realpath ./i3) $HOME/.config/
ln -s $(realpath ./polybar) $HOME/.config/
ln -s $(realpath ./rofi) $HOME/.config/
ln -s $(realpath ./dunst) $HOME/.config/

rm -rf $HOME/.urxvt
ln -s $(realpath ./urxvt) $HOME/.urxvt
rm -rf $HOME/.tmux
ln -s $(realpath ./tmux) $HOME/.tmux
rm -rf $HOME/images
ln -s $(realpath ./images) $HOME/images

ln -s $(realpath ./Xdefaults) $HOME/.Xdefaults
ln -s $(realpath ./Xresources) $HOME/.Xresources
ln -s $(realpath ./vimrc) $HOME/.vimrc
ln -s $(realpath ./tmux.conf) $HOME/.tmux.conf

rm -rf $HOME/.zshrc
ln -s $(realpath ./zshrc) $HOME/.zshrc

mkdir -p $HOME/bin/screen
ln -s /home/efazati/.screenlayout/1mon.sh $HOME/bin/screen/default.sh


sudo chmod a+rw $OH_ZSH_PATH

git clone https://github.com/zsh-users/zsh-autosuggestions.git $OH_ZSH_PATH/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $OH_ZSH_PATH/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${OH_ZSH_PATH:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $OH_ZSH_PATH/plugins/zsh-autocomplete

chmod 755 $HOME/.oh-my-zsh/plugins/*

sudo chmod 777 /etc/wireguard 

# INSERT_YOUR_USERNAME ALL = (root) NOPASSWD: /usr/bin/wg-quick
# /etc/sudoers.d/wiregaurd

# sudo ln -s /opt/Synergy/synergy /usr/local/bin

mkdir -p ~/.vim/pack/plugins/start && git clone https://github.com/mg979/vim-visual-multi ~/.vim/pack/plugins/start/vim-visual-multi 

git clone --depth=1 https://github.com/tfutils/tfenv.git $HOME/.tfenv

### 1Password
sudo -s \
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
tee /etc/apt/sources.list.d/1password.list
mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
apt update && apt install 1password-cli


### Docker
sh -c "$(curl -fsSL https://get.docker.com )"

### Cursor / VSCode
rm -rf ~/.config/Cursor/User/keybindings.json
ln -s $(realpath vscode/keybindings.json) ~/.config/Cursor/User/keybindings.json
rm -rf ~/.config/Cursor/User/settings.json
ln -s $(realpath vscode/settings.json) ~/.config/Cursor/User/settings.json
