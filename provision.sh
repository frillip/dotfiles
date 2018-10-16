#!/bin/bash
# This script installs dependencies required by dotfiles, and then the configuration files with git repo.

# CAVEAT: nvim not installed on raspbian (apt version too old)

set -e
set -x
# curl -sL https://github.com/naggie/dotfiles/raw/master/provision.sh | bash && bash

cat <<EOF
This script is intended to be run once. It will install packages then sync
dotfiles.

Hit CTRL+C to abort in the next 3 seconds....

EOF

sleep 3

# tmpreaper tries to do a post-install "configuration" screen to warn the user.
export DEBIAN_FRONTEND=noninteractive

# packages are installed via the stock system package manager unless a more
# recent version is available elsewhere.

if [ $(uname) == 'Darwin' ]; then
    # macos
    if [ ! -f /usr/local/bin/brew ]; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        brew update
    fi

    # recommended, uses /Applications now.
    brew tap caskroom/homebrew-cask
    brew cask install spectacle firefox

    # flux is no longer required -- night shift!

    # Upgrade or install (logic necessary)
    packages=(tmux vim git tig httpie ncdu tree bash openssh jq wget task htop gnupg2 bash-completion keychain iproute2mac tmpreaper \
        coreutils sox ffmpeg httrack python ripgrep python go)
    for package in "${packages[@]}"; do
        brew upgrade $package || brew install $package
    done

    python3 -m pip install --upgrade pip
    python3 -m pip install --upgrade ansible ipython

    # correct so alias works cross platform
    ln -sf /usr/local/bin/gpg /usr/local/bin/gpg2

elif grep -q Ubuntu /etc/issue || grep -q Raspbian /etc/issue; then
    if grep -q Ubuntu /etc/issue; then
        sudo -E apt-add-repository multiverse
        sudo -E apt-get -y install language-pack-en
        sudo -E apt-get -y install curl
        # FYI -- ripgrep is an official 18.04 package
        curl -L https://github.com/BurntSushi/ripgrep/releases/download/0.10.0/ripgrep_0.10.0_amd64.deb > /tmp/ripgrep.deb
        sudo dpkg -i /tmp/ripgrep.deb
        rm /tmp/ripgrep.deb
    else
        curl -L https://github.com/BurntSushi/ripgrep/releases/download/0.10.0/ripgrep-0.10.0-arm-unknown-linux-gnueabihf.tar.gz \
            | sudo tar -C /usr/local/bin --strip=1 -xzf - ripgrep-0.10.0-arm-unknown-linux-gnueabihf/rg
    fi

    sudo -E apt-get -y update
    sudo -E apt-get -y install tmux vim git tig ssh figlet httpie ncdu tree wget htop gnupg2 curl keychain tmpreaper bash-completion \
        jq sox ffmpeg httrack python python3 golang libffi-dev python-pip python3-pip python-dev python3-dev libssl-dev dconf-cli

    sudo python3 -m pip install --upgrade pip
    sudo python3 -m pip install --upgrade ansible ipython

    sudo -E ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
else
    echo "Unsupported OS."
    exit 2
fi


# all platforms

# FZF
test ! -d ~/.fzf && git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
git -C ~/.fzf pull origin master
~/.fzf/install --all

# clone main repository to home
cd ~
test ! -d ~/dotfiles && git clone https://github.com/naggie/dotfiles.git
cd dotfiles
git pull --ff-only origin master

# Adobe source code pro (powershell patched)
./etc/powerline-patched/install.sh

# install dotfiles configuration
./install.sh

# generate fish completions now that all cmds are installed
if which fish > /dev/null; then
    fish -c fish_update_completions
fi
