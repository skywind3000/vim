let s:home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
command! -nargs=1 IncScript exec 'so '. fnameescape(s:home."/<args>")
exec 'set rtp+='. fnameescape(s:home)
exec 'set rtp+=~/.vim'

if exists(':packadd')
	exec 'set packpath+=' . fnameescape(s:home . '/site')
endif

IncScript init/viminit.vim
IncScript init/config.vim

IncScript init/vimmake.vim
IncScript init/ignores.vim
IncScript init/tools.vim
IncScript init/keymaps.vim
IncScript init/plugins.vim
IncScript init/status.vim

IncScript init/misc.vim
IncScript init/gui.vim
IncScript init/menu.vim
IncScript init/unix.vim


if has('nvim') == 0
	let name = expand('~/.vim/local.vim')
else
	if $XDG_CONFIG_HOME != ''
		let name = $XDG_CONFIG_HOME . '/nvim/local.vim'
	else
		let name = expand('~/.config/nvim/local.vim')
	endif
endif

if filereadable(name)
	exec 'source ' . fnameescape(name)
endif



