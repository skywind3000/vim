#! /bin/sh

set -e
set -x

export DEBIAN_FRONTEND=noninteractive

mkdir -p ~/.vim
cd ~/.vim

git clone https://github.com/skywind3000/vim.git
cd ~/.vim/vim/etc
sh update.sh

cd ~
echo 'let g:bundle_group = ["simple"]' >> ~/.vimrc
echo 'so ~/.vim/vim/vimrc.unix' >> ~/.vimrc

echo 'source ~/.local/etc/init.sh' >> ~/.bashrc
echo 'umask 022' >> ~/.bashrc

