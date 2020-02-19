#! /bin/sh
# https://github.com/skywind3000/vim/raw/master/tools/script/bootstrap.sh

set -e
set -x

export DEBIAN_FRONTEND=noninteractive

mkdir -p ~/.ssh
chmod 700 ~/.ssh
cd ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEA2yNZF/SKiYaFKHlpi4HoSxDMIDJfJsjL4+ZbdkNxxscSY02O95txYkwNrQJNLRPVCMy+d5027AuKvT/yKptzJ1POszxUGXqCE/cAb8idAptYu2r1FpWvPzdK1l7UmDrUzr0frvk64hlyeOPjvQ7bFko96NI5UuCFnCpFcC8oTnM= skywind" >> authorized_keys

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


