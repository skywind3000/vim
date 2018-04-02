#! /bin/sh

SCRIPT=$(readlink "$0")
SCRIPTPATH=$(dirname "$SCRIPT")


[ ! -d "$HOME/.local" ] && mkdir -p "$HOME/.local" 2> /dev/null
[ ! -d "$HOME/.local/etc" ] && mkdir -p "$HOME/.local/etc" 2> /dev/null
[ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin" 2> /dev/null
[ ! -d "$HOME/.local/lib" ] && mkdir -p "$HOME/.local/lib" 2> /dev/null
[ ! -d "$HOME/.local/lib/python" ] && mkdir -p "$HOME/.local/lib/python" 2> /dev/null
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config" 2> /dev/null
[ ! -d "$HOME/.config/fish" ] && mkdir -p "$HOME/.config/fish" 2> /dev/null


cp $SCRIPTPATH/*.sh "$HOME/.local/etc/" 
cp $SCRIPTPATH/*.conf "$HOME/.local/etc/" 
cp $SCRIPTPATH/*.fish "$HOME/.config/fish/"
cp $SCRIPTPATH/*.zsh "$HOME/.local/etc/"
cp $SCRIPTPATH/*.lua "$HOME/.local/etc/"
cp $SCRIPTPATH/inputrc "$HOME/.local/etc"

cp $SCRIPTPATH/../tools/bin/* "$HOME/.local/bin"
cp $SCRIPTPATH/../lib/* "$HOME/.local/lib/python"



