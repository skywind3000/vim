"======================================================================
"
" auxlib.vim - python + vim
"
" Created by skywind on 2016/11/07
" Last change: 2016/11/07 11:57:54
"
"======================================================================
if !has('python3')
	finish
endif

let s:filename = expand('<sfile>:p')
let s:filehome = expand('<sfile>:p:h')

python3 << __EOF__
def __auxlib_initialize():
	import os, sys, vim
	filename = os.path.abspath(vim.eval('expand("<sfile>:p")'))
	filehome = os.path.abspath(os.path.dirname(filename))
	if not filehome in sys.path:
		sys.path.append(filehome)
	return 0

__auxlib_initialize()
import auxlib
__EOF__




"----------------------------------------------------------------------
" tweak
"----------------------------------------------------------------------
let g:auxlib_tweak_alpha = 255

function! auxlib#tweak_set_alpha(alpha)
    pyx import vim
    pyx tweak = auxlib.VimTweakGetInstance()
    pyx tweak.SetAlpha(vim.eval('a:alpha'))
	let g:auxlib_tweak_alpha = 0 + a:alpha
endfunc

function! auxlib#tweak_enable_capture(enable)
	let l:enable = 1
	if a:enable == '!' || a:enable == 0
		let l:enable = 0
	endif
    pyx import vim
    pyx tweak = auxlib.VimTweakGetInstance()
    pyx tweak.EnableCaption(vim.eval('l:enable'))
endfunc

function! auxlib#tweak_enable_maximize(enable)
	let l:enable = 0
	if a:enable == '' || a:enable != 0
		let l:enable = 1
	endif
    pyx import vim
    pyx tweak = auxlib.VimTweakGetInstance()
    pyx tweak.EnableMaximize(vim.eval('l:enable'))
endfunc

function! auxlib#tweak_enable_topmost(enable)
	let l:enable = 0
	if a:enable == '' || a:enable != 0
		let l:enable = 1
	endif
    pyx import vim
    pyx tweak = auxlib.VimTweakGetInstance()
    pyx tweak.EnableTopMost(vim.eval('l:enable'))
endfunc

function! auxlib#tweak_convert(image, color, alpha, width, height)
    pyx import vim
    pyx tweak = auxlib.VimTweakGetInstance()
    pyx nargs = []
    pyx nargs.append("~/.vim/wallpaper.bmp")
    pyx nargs.append(vim.eval('a:image'))
	if a:width > 0 && a:height > 0
		python nargs.append((int(vim.eval('a:width')), int(vim.eval('a:height'))))
	else
		python nargs.append(None)
	endif
    pyx nargs.append(int(vim.eval('a:color')))
    pyx nargs.append(int(vim.eval('a:alpha')))
    pyx tweak.ConvertImage(*nargs)
    pyx del nargs
endfunc

function! auxlib#tweak_wallpaper(image)
	let imgx = get(g:, 'auxlib#wallpaper_width', -1)
	let imgy = get(g:, 'auxlib#wallpaper_height', -1)
	let color = get(g:, 'auxlib#wallpaper_color', -1)
	let alpha = get(g:, 'auxlib#wallpaper_alpha', 35)
	if color < 0
		let color = str2nr(synIDattr(hlID('Normal'), 'bg#')[1:], 16)
	endif
	call auxlib#tweak_convert(a:image, color, alpha, imgx, imgy)
	call bgimg#set_bg(color)
	call bgimg#set_image(expand("~/.vim/") . "wallpaper.bmp")
endfunc

function! auxlib#clear_leader_mru()
	let name = '~/.vim/cache/.LfCache/python3/mru'
endfunc


