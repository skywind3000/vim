let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
command! -nargs=1 IncScript exec 'so '. fnameescape(s:home."/<args>")
exec 'set rtp+='.s:home
exec 'set rtp+=~/.vim'

IncScript init/viminit.vim
IncScript init/vimmake.vim

VimmakeKeymap

IncScript init/config.vim

IncScript init/ignores.vim
IncScript init/tools.vim
IncScript init/keymaps.vim
IncScript init/plugins.vim
IncScript init/status.vim

IncScript init/misc.vim
IncScript init/gui.vim
IncScript init/menu.vim
IncScript init/unix.vim


