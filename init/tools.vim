"======================================================================
"
" tools.vim - tool functions
"
" Created by skywind on 2018/02/10
" Last Modified: 2018/02/10 02:34:43
"
"======================================================================

" Open Explore in new tab with current directory
function! Open_Explore(where)
	let l:path = expand("%:p:h")
	if l:path == ''
		let l:path = getcwd()
	endif
	if a:where < 0
		exec 'Rexplore'
	elseif a:where == 0
		exec 'Explore '
	elseif a:where == 1
		exec 'Vexplore! '
	elseif a:where == 2
		exec 'Texplore'
	endif
endfunc

function! Open_Browse(where)
	let l:path = expand("%:p:h")
	if l:path == '' | let l:path = getcwd() | endif
	if exists('g:browsefilter') && exists('b:browsefilter')
		if g:browsefilter != ''
			let b:browsefilter = g:browsefilter
		endif
	endif
	if a:where == 0
		exec 'browse e '.fnameescape(l:path)
	elseif a:where == 1
		exec 'browse vnew '.fnameescape(l:path)
	else
		exec 'browse tabnew '.fnameescape(l:path)
	endif
endfunc


function! Transparency_Set(value)
	if (has('win32') || has('win64'))
		let l:alpha = (100 - a:value) * 255 / 100
		if l:alpha >= 255 
			let l:alpha = 255 
		endif
		if l:alpha < 0 
			let l:alpha = 0 
		endif
		call auxlib#tweak_set_alpha(l:alpha)
	elseif has('gui_macvim')
		if a:value >= 100
			set transparency = 100
		elseif a:value >= 0
			let &transparency = a:value
		else
			set transparency = 0
		endif
	endif
endfunc

function! Transparency_Get()
	if (has('win32') || has('win64')) 
		if exists('g:auxlib_tweak_alpha')
			return (255 - g:auxlib_tweak_alpha) * 100 / 255
		else
			return 0
		endif
	elseif has('gui_macvim')
		return &transparency
	endif
	return 0
endfunc

function! Change_Transparency(increase)
	let l:current = Transparency_Get()
	if a:increase < 0
		let l:inc = -a:increase
		if l:inc > l:current
			silent call Transparency_Set(0)
		else
			silent call Transparency_Set(l:current - l:inc)
		endif
	elseif a:increase > 0
		let l:inc = a:increase
		if l:inc + l:current > 100
			silent call Transparency_Set(100)
		else
			silent call Transparency_Set(l:current + l:inc)
		endif
	endif
	echo 'transparency: '.l:current
endfunc

function! Toggle_Transparency(value)
	let l:current = Transparency_Get()
	if Transparency_Get() > 0
		call Transparency_Set(0)
	else
		call Transparency_Set(a:value)
	endif
endfunc

" delete buffer keep window
function! s:BufferClose(bang, buffer)
	let l:bufcount = bufnr('$')
	let l:switch = 0 	" window which contains target buffer will be switched
	if empty(a:buffer)
		let l:target = bufnr('%')
	elseif a:buffer =~ '^\d\+$'
		let l:target = bufnr(str2nr(a:buffer))
	else
		let l:target = bufnr(a:buffer)
	endif
	if l:target <= 0
		echohl ErrorMsg
		echomsg "cannot find buffer: '" . a:buffer . "'"
		echohl NONE
		return 0
	endif
	if !getbufvar(l:target, "&modifiable")
		echohl ErrorMsg
		echomsg "Cannot close a non-modifiable buffer"
		echohl NONE
		return 0
	endif
	if empty(a:bang) && getbufvar(l:target, '&modified')
		echohl ErrorMsg
		echomsg "No write since last change (use :BufferClose!)"
		echohl NONE
		return 0
	endif
	if bufnr('#') > 0	" check alternative buffer
		let l:aid = bufnr('#')
		if l:aid != l:target && buflisted(l:aid) && getbufvar(l:aid, "&modifiable")
			let l:switch = l:aid	" switch to alternative buffer
		endif
	endif
	if l:switch == 0	" check non-scratch buffers
		let l:index = l:bufcount
		while l:index >= 0
			if buflisted(l:index) && getbufvar(l:index, "&modifiable")
				if strlen(bufname(l:index)) > 0 && l:index != l:target
					let l:switch = l:index	" switch to that buffer
					break
				endif
			endif
			let l:index = l:index - 1	
		endwhile
	endif
	if l:switch == 0	" check scratch buffers
		let l:index = l:bufcount
		while l:index >= 0
			if buflisted(l:index) && getbufvar(l:index, "&modifiable")
				if l:index != l:target
					let l:switch = l:index	" switch to a scratch
					break
				endif
			endif
			let l:index = l:index - 1
		endwhile
	endif
	if l:switch  == 0	" check if only one scratch left
		if strlen(bufname(l:target)) == 0 && (!getbufvar(l:target, "&modified"))
			echo "This is the last scratch" 
			return 0
		endif
	endif
	let l:ntabs = tabpagenr('$')
	let l:tabcc = tabpagenr()
	let l:wincc = winnr()
	let l:index = 1
	while l:index <= l:ntabs
		exec 'tabn '.l:index
		while 1
			let l:wid = bufwinnr(l:target)
			if l:wid <= 0 | break | endif
			exec l:wid.'wincmd w'
			if l:switch == 0
				exec 'enew!'
				let l:switch = bufnr('%')
			else
				exec 'buffer '.l:switch
			endif
		endwhile
		let l:index += 1
	endwhile
	exec 'tabn ' . l:tabcc
	exec l:wincc . 'wincmd w'
	exec 'bdelete! '.l:target
	return 1
endfunction

command! -bang -nargs=? BufferClose call s:BufferClose('<bang>', '<args>')

" write a log
function! LogWrite(text)
	call asclib#utils#log(a:text)
endfunc


" toggle taglist
function! Toggle_Taglist()
	call LogWrite('[taglist] '.expand("%:p"))
	silent exec 'TlistToggle'
endfunc

" open explorer/finder
function! Show_Explore()
	let l:locate = expand("%:p:h")
	if has('win32') || has('win64') || has('win16')
		exec "!start /b cmd.exe /C explorer.exe ".shellescape(l:locate)
	endif
endfunc


function! Tools_BellUnix()
    let l:t_ti = &t_ti
    let l:t_te = &t_te
    let &t_ti = ""
    let &t_te = ""
    silent !printf "\a"
    redraw!
    let &t_ti = l:t_ti
    let &t_te = l:t_te
endfunc

function! Tools_BellConflict()
	silent exec 'norm! \<ESC>'
endfunc

function! Tools_SwitchLayout() 
	set number
	set showtabline=2
	set laststatus=2
	set signcolumn=yes
	if !has('gui_running')
		set t_Co=256
	endif
	if $SSH_CONNECTION != ''
		let g:vimmake_build_bell = 1
		let g:asyncrun_bell = 1
	endif
endfunc


function! Tools_SwitchSigns()
	if (!has('signs')) || (!has('patch-7.4.2210'))
		return 0
	endif
	if &signcolumn == 'auto'
		set signcolumn=yes
		echo ':signcolumn=yes'
	elseif &signcolumn == 'yes'
		set signcolumn=no
		echo ':signcolumn=no'
	else
		set signcolumn=auto
		echo ':signcolumn=auto'
	endif
endfunc


function! Tools_ListMeta(mapmode, upper)
	let text = []
	for i in range(26)
		let ch = nr2char(char2nr(a:upper? 'A' : 'a') + i)
		redir => x
		exec "silent ". a:mapmode . " <M-" . ch . ">"
		redir END
		let x = substitute(x, '^\s*\(.\{-}\)\s*\n*$', '\1', '')
		let h = "<M-". ch . ">     "
		if x =~ 'No mapping found'
			let text += [h . "                 ---<free>---"]
		else
			for y in split(x, '\n')
				let z = substitute(y, '\n', '', 'g')
				let text += [h .z]
			endfor
		endif
	endfor
	call sort(text)
	for x in text
		echo x
	endfor
endfunc


command! -nargs=1 -bang AscListMeta 
			\ call Tools_ListMeta(<q-args>, <bang>0)


function! Tools_ProfileStart(filename)
	silent! profile stop
	if filereadable(a:filename)
		call delete(a:filename)
	endif
	exec "profile start ".fnameescape(a:filename)
	profile func *
	profile file *
endfunc

function! Tools_ProfileStop()
	profile stop
endfunc


function! Tools_SwitchMakeFile()
	let root = asclib#path#get_root('%')
	let name = asclib#path#join(root, 'Makefile')
	exec 'FileSwitch '. fnameescape(name)
endfunc




"----------------------------------------------------------------------
" https://github.com/lilydjwg/dotvim 
"----------------------------------------------------------------------
function! GetPatternAtCursor(pat)
	let col = col('.') - 1
	let line = getline('.')
	let ebeg = -1
	let cont = match(line, a:pat, 0)
	while (ebeg >= 0 || (0 <= cont) && (cont <= col))
		let contn = matchend(line, a:pat, cont)
		if (cont <= col) && (col < contn)
			let ebeg = match(line, a:pat, cont)
			let elen = contn - ebeg
			break
		else
			let cont = match(line, a:pat, contn)
		endif
	endwhile
	if ebeg >= 0
		return strpart(line, ebeg, elen)
	else
		return ""
	endif
endfunc

"----------------------------------------------------------------------
" Align cheatsheet
"----------------------------------------------------------------------
function! s:Tools_CheatSheetAlign(...)
	let size = get(g:, 'tools_align_width', 20)
	let size = (a:0 >= 1 && a:1 > 0)? a:1 : size
	let text = 's/^\(\S\+\%( \S\+\)*\)\s\s\+/\=printf("%-'
	let text.= size
	let text.= 'S",submatch(1))/'
	let text = 's/^\(.\{-}\) \{2,}/\=printf("%-'. size
	let text.= 'S", submatch(1))/'
	silent! keepjumps exec text
endfunc

command! -nargs=? -range MyCheatSheetAlign <line1>,<line2>call s:Tools_CheatSheetAlign(<q-args>)


"----------------------------------------------------------------------
" Remove some path from $PATH
"----------------------------------------------------------------------
function! s:RemovePath(path) abort
	let windows = 0
	let path = a:path
	let sep = ':'
	let parts = []
	if has('win32') || has('win64') || has('win32unix') || has('win95')
		let windows = 1
		let path = tolower(path)
		let path = asclib#string#replace(path, '\', '/')
		let sep = ';'
	endif
	for n in split($PATH, sep)
		let key = n
		if windows != 0 
			let key = tolower(key)
			let key = asclib#string#replace(key, '\', '/')
		endif
		if key != path 
			let parts += [n]
		endif
	endfor
	let text = join(parts, sep)
	let $PATH = text
endfunc

command! -nargs=1 EnvPathRemove call s:RemovePath(<q-args>)




