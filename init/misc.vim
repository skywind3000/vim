"======================================================================
"
" misc.vim - 
"
" Created by skywind on 2018/02/10
" Last Modified: 2018/02/19 02:07:04
"
"======================================================================

"-----------------------------------------------------------------------
" insert before current line
"-----------------------------------------------------------------------
function! s:snip(text)
	call append(line('.') - 1, a:text)
endfunc


"-----------------------------------------------------------------------
" guess comment
"-----------------------------------------------------------------------
function! s:comment()
	let l:ext = expand('%:e')
	if &filetype == 'vim'
		return '"'
	elseif index(['c', 'cpp', 'h', 'hpp', 'hh', 'cc', 'cxx'], l:ext) >= 0
		return '//'
	elseif index(['m', 'mm', 'java', 'go', 'delphi', 'pascal'], l:ext) >= 0
		return '//'
	elseif index(['coffee', 'as'], l:ext) >= 0
		return '//'
	elseif index(['c', 'cpp', 'rust', 'go', 'javascript'], &filetype) >= 0
		return '//'
	elseif index(['coffee'], &filetype) >= 0
		return '//'
	elseif index(['sh', 'bash', 'python', 'php', 'perl', 'zsh'], $filetype) >= 0
		return '#'
	elseif index(['make', 'ruby', 'text'], $filetype) >= 0
		return '#'
	elseif index(['py', 'sh', 'pl', 'php', 'rb'], l:ext) >= 0
		return '#'
	elseif index(['asm', 's'], l:ext) >= 0
		return ';'
	elseif index(['asm'], &filetype) >= 0
		return ';'
	elseif index(['sql', 'lua'], l:ext) >= 0
		return '--'
	elseif index(['basic'], &filetype) >= 0
		return "'"
	endif
	return "#"
endfunc


"-----------------------------------------------------------------------
" comment bar
"-----------------------------------------------------------------------
function! s:comment_bar(repeat, limit)
	let l:comment = s:comment()
	while strlen(l:comment) < a:limit
		let l:comment .= a:repeat
	endwhile
	return l:comment
endfunc


"-----------------------------------------------------------------------
" comment block
"-----------------------------------------------------------------------
function! <SID>snip_comment_block(repeat)
	let l:comment = s:comment()
	let l:complete = s:comment_bar(a:repeat, 71)
	if l:comment == ''
		return
	endif
	call s:snip('')
	call s:snip(l:complete)
	call s:snip(l:comment . ' ')
	call s:snip(l:complete)
endfunc


"-----------------------------------------------------------------------
" copyright
"-----------------------------------------------------------------------
function! <SID>snip_copyright(author)
	let l:c = s:comment()
	let l:complete = s:comment_bar('=', 71)
	let l:filename = expand("%:t")
	let l:t = strftime("%Y/%m/%d")
	let l:text = []
	if &filetype == 'python'
		let l:text += ['#! /usr/bin/env python']
		let l:text += ['# -*- coding: utf-8 -*-']
	elseif &filetype == 'sh'
		let l:text += ['#! /bin/sh']
	elseif &filetype == 'perl'
		let l:text += ['#! /usr/bin/env perl']
	elseif &filetype == 'bash'
		let l:text += ['#! /usr/bin/env bash']
	elseif &filetype == 'zsh'
		let l:text += ['#! /usr/bin/env zsh']
	elseif &filetype == 'php'
	endif
	let l:text += [l:complete]
	let l:text += [l:c]
	let l:text += [l:c . ' ' . l:filename . ' - ' ]
	let l:text += [l:c]
	let l:text += [l:c . ' Created by ' . a:author . ' on '. l:t]
	let l:text += [l:c . ' Last Modified: ' . strftime('%Y/%m/%d %H:%M:%S') ]
	let l:text += [l:c]
	let l:text += [l:complete]
	call append(0, l:text)
endfunc


"----------------------------------------------------------------------
" bundle setup
"----------------------------------------------------------------------
function! <SID>snip_bundle()
	let l:text = []
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ['" Bundle Header']
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ["set nocompatible"]
	let l:text += ["filetype off"]
	let l:text += ["set rtp+=~/.vim/bundle/Vundle.vim"]
	let l:text += ["call vundle#begin()"]
	let l:text += ["Plugin 'VundleVim/Vundle.vim'"]
	let l:text += [""]
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ['" Plugins']
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ["\" Plugin 'SirVer/ultisnips'"]
	let l:text += ["\" Plugin 'honza/vim-snippets'"]
	let l:text += [""]
	let l:text += [""]
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ['" Bundle Footer']
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ["call vundle#end()"]
	let l:text += ["filetype on"]
	let l:text += [""]
	let l:text += [""]
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += ['" Settings']
	let l:text += ['"----------------------------------------------------------------------']
	let l:text += [""]
	let l:text += [""]
	call append(line('.') - 1, l:text)
endfunc


"----------------------------------------------------------------------
" main test
"----------------------------------------------------------------------
function! <SID>snip_main()
	let l:ext = expand('%:e')
	let l:text = []
	if &filetype == 'vim'
	elseif index(['c', 'cpp', 'h', 'hpp', 'hh', 'cc', 'cxx'], l:ext) >= 0
		let l:text += ['#include <stdio.h>']
		let l:text += ['#include <stdlib.h>']
		let l:text += ['']
		let l:text += ['int main(void)']
		let l:text += ['{']
		let l:text += ["\tprintf(\"Hello World !!\\n\");"]
		let l:text += ["\treturn 0;"]
		let l:text += ['{']
	elseif &filetype == 'python'
		let l:text += ['#! /usr/bin/env python']
		let l:text += ['# -*- coding: utf-8 -*-']
		let l:text += ['import sys']
		let l:text += ['import time']
		let l:text += ['import os']
		let l:text += ['import codecs']
		let l:text += ['']
		let l:text += ['']
		let l:text += ['']
		let l:text += ['if __name__ == "__main__":']
		let l:text += ["\tprint('Hello, World !!')"]
	endif
	call append(line('.') - 1, l:text)
endfunc


"----------------------------------------------------------------------
" insert mode line
"----------------------------------------------------------------------
function! <SID>snip_modeline()
	let text = '" vim: set '
	let text .= (&l:et)? 'et ' : 'noet '
	let text .= 'fenc='. (&l:fenc) . ' '
	let text .= 'ff='. (&l:ff) . ' '
	let text .= 'sts='. (&l:sts). ' '
	let text .= 'sw='. (&l:sw). ' '
	let text .= 'ts='. (&l:ts). ' '
	let text .= ':'
	call append(line('.') - 1, text)
endfunc


"-----------------------------------------------------------------------
" hot keys
"-----------------------------------------------------------------------
noremap <space>e- :call <SID>snip_comment_block('-')<cr>
noremap <space>e= :call <SID>snip_comment_block('=')<cr>
noremap <space>e# :call <SID>snip_comment_block('#')<cr>
noremap <space>ec :call <SID>snip_copyright('skywind')<cr>
noremap <space>eb :call <SID>snip_bundle()<cr>
noremap <space>em :call <SID>snip_main()<cr>
noremap <space>el :call <SID>snip_modeline()<cr>
noremap <space>et "=strftime("%Y/%m/%d %H:%M:%S")<CR>gp


"----------------------------------------------------------------------
" insert mode fast
"----------------------------------------------------------------------
inoremap <c-x>( ()<esc>i
inoremap <c-x>[ []<esc>i
inoremap <c-x>' ''<esc>i
inoremap <c-x>" ""<esc>i
inoremap <c-x>< <><esc>i
inoremap <c-x>{ {<esc>o}<esc>ko

if has('gui_running')
	inoremap <M-(> ()<esc>i
	inoremap <M-[> []<esc>i
	inoremap <M-'> ''<esc>i
	inoremap <M-"> ""<esc>i
	inoremap <M-<> <><esc>i
	inoremap <M-{> {<esc>o}<esc>ko
endif



