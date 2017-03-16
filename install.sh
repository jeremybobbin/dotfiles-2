#!/bin/sh

set -e
IFS='
'

install_scripts=yes
if $(command -v enchive > /dev/null 2>&1); then
    install_private=yes
else
    install_private=no
fi

usage() {
    cat << EOF
usage: install.sh [options]

OPTIONS:
  -h    Show this message
  -p    Don't install private dotfiles
  -s    Don't install bin/ scripts
EOF
    exit $1
}

## Parse command line switches
while getopts "hps" option; do
    case "$option" in
        h) usage 0 ;;
        p) install_private=no ;;
        s) install_scripts=no ;;
        ?) usage 1 ;;
    esac
done

## Install scripts
bin=~/.local/bin
mkdir -p "$bin"
if [ $install_scripts = yes ]; then
    echo Installing scripts
    for script in $(find bin -type f -perm -+x); do
        ln -fs -- "$(pwd)/$script" "$bin"
    done
fi

## Installs an individual dotfile
install() {
    dotfile="$1"
    dest="$HOME/.${dotfile#./_*}"
    if [ "$dotfile" = "${dotfile##*.enchive}" ]; then
        echo Installing "$dotfile"
        mkdir -p -m 700 "$(dirname "$dest")"
        chmod go-rwx "$dotfile"
        ln -fs "$(pwd)/$dotfile" "$dest"
    elif [ $install_private = yes ]; then
        dest="${dest%.enchive}"
        if [ ! -e "$dest" -o "$dotfile" -nt "$dest" ]; then
            echo Decrypting "$dotfile"
            mkdir -p -m 700 "$(dirname "$dest")"
            (umask 0177;
             enchive --agent extract "$dotfile" "$dest")
        else
            echo Skipping "$dotfile"
        fi
    fi
}

## Install each _-prefixed file
for source in $(find . -name '_*' | sort); do
    if [ -d "$source" ]; then
        for dotfile in $(find "$source" -type f | sort); do
            install "$dotfile"
        done
    else
        install "$source"
    fi
done

## Special cases
mkdir -p ~/.vim
ln -sf /dev/null ~/.bash_history
chmod -w _config/vlc/vlcrc  # Disables annoying VLC clobbering
awk 'FNR==1{print ""}1' ~/.ssh/config.d/* > ~/.ssh/config
