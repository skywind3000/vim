"======================================================================
"
" asclib.vim - autoload methods
"
" Created by skywind on 2016/10/28
" Last change: 2016/10/28 00:38:10
"
"======================================================================


"----------------------------------------------------------------------
" window basic
"----------------------------------------------------------------------

" save all window's view
function! asclib#window_saveview()
	function! s:window_view_save()
		let w:asclib_window_view = winsaveview()
	endfunc
	let l:winnr = winnr()
	noautocmd windo call s:window_view_save()
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc

" restore all window's view
function! asclib#window_loadview()
	function! s:window_view_rest()
		if exists('w:asclib_window_view')
			call winrestview(w:asclib_window_view)
			unlet w:asclib_window_view
		endif
	endfunc
	let l:winnr = winnr()
	noautocmd windo call s:window_view_rest()
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc

" unique window id
function! asclib#window_uid(tabnr, winnr)
	let name = 'asclib_window_unique_id'
	let uid = gettabwinvar(a:tabnr, a:winnr, name)
	if type(uid) == 1 && uid == ''
		if !exists('s:asclib_window_unique_index')
			let s:asclib_window_unique_index = 1000
			let s:asclib_window_unique_rewind = 0
			let uid = 1000
			let s:asclib_window_unique_index += 1
		else
			let uid = 0
			if !exists('s:asclib_window_unique_rewind')
				let s:asclib_window_unique_rewind = 0
			endif
			if s:asclib_window_unique_rewind == 0 
				let uid = s:asclib_window_unique_index
				let s:asclib_window_unique_index += 1
				if s:asclib_window_unique_index >= 100000
					let s:asclib_window_unique_rewind = 1
					let s:asclib_window_unique_index = 1000
				endif
			else
				let name = 'asclib_window_unique_id'
				let index = s:asclib_window_unique_index
				let l:count = 0
				while l:count < 100000
					let found = 0
					for l:tabnr in range(1, tabpagenr('$'))
						for l:winnr in range(1, tabpagewinnr(l:tabnr, '$'))
							if gettabwinvar(l:tabnr, l:winnr, name) is index
								let found = 1
								break
							endif
						endfor
						if found != 0
							break
						endif
					endfor
					if found == 0
						let uid = index
					endif
					let index += 1
					if index >= 100000
						let index = 1000
					endif
					let l:count += 1
					if found == 0
						break
					endif
				endwhile
				let s:asclib_window_unique_index = index
			endif
			if uid == 0
				echohl ErrorMsg
				echom "error allocate new window uid"
				echohl NONE
				return -1
			endif
		endif
		call settabwinvar(a:tabnr, a:winnr, name, uid)
	endif
	return uid
endfunc

" unique window id to [tabnr, winnr], [0, 0] for not find
function! asclib#window_find(uid)
	let name = 'asclib_window_unique_id'
	" search current tabpagefirst
	for l:winnr in range(1, winnr('$'))
		if gettabwinvar('%', l:winnr, name) is a:uid
			return [tabpagenr(), l:winnr]
		endif
	endfor
	" search all the tabpages
	for l:tabnr in range(1, tabpagenr('$'))
		for l:winnr in range(1, tabpagewinnr(l:tabnr, '$'))
			if gettabwinvar(l:tabnr, l:winnr, name) is a:uid
				return [l:tabnr, l:winnr]
			endif
		endfor
	endfor
	return [0, 0]
endfunc

" switch to tabwin
function! asclib#window_goto_tabwin(tabnr, winnr)
	if a:tabnr != '' && a:tabnr != '%'
		if tabpagenr() != a:tabnr
			silent! exec "tabn ". a:tabnr
		endif
	endif
	if winnr() != a:winnr
		silent! exec ''.a:winnr.'wincmd w'
	endif
endfunc

" switch to window by uid
function! asclib#window_goto_uid(uid)
	let [l:tabnr, l:winnr] = asclib#window_find(a:uid)
	if l:tabnr == 0 || l:winnr == 0
		return 1
	endif
	call asclib#window_goto_tabwin(l:tabnr, l:winnr)
	return 0
endfunc

" new window and return window uid, zero for error
function! asclib#window_new(position, size, avoid)
	function! s:window_new_action(mode)
		if a:mode == 0
			let w:asclib_window_saveview = winsaveview()
		else
			if exists('w:asclib_window_saveview')
				call winrestview(w:asclib_window_saveview)
				unlet w:asclib_window_saveview
			endif
		endif
	endfunc
	let uid = asclib#window_uid('%', '%')
	let retval = 0
	noautocmd windo call s:window_new_action(0)
	noautocmd call asclib#window_goto_uid(uid)
	if type(a:avoid) == 3
		for i in range(winnr('$'))
			let ok = 1
			let bt = &buftype
			for skip in a:avoid
				if skip == bt
					let ok = 0
					break
				endif
			endfor
			if ok != 0
				break
			endif
			noautocmd wincmd w
		endfor
	endif
	if a:position == 'top' || a:position == '0'
		if a:size <= 0
			leftabove new 
		else
			exec 'leftabove '.a:size.'new'
		endif
	elseif a:position == 'bottom' || a:position == '1'
		if a:size <= 0
			rightbelow new
		else
			exec 'rightbelow '.a:size.'new'
		endif
	elseif a:position == 'left' || a:position == '2'
		if a:size <= 0
			leftabove vnew
		else
			exec 'leftabove '.a:size.'vnew'
		endif
	elseif a:position == 'right' || a:position == '3'
		if a:size <= 0
			rightbelow vnew
		else
			exec 'rightbelow '.a:size.'vnew'
		endif
	else
		rightbelow vnew
	endif
	let retval = asclib#window_uid('%', '%')
	noautocmd windo call s:window_new_action(1)
	if retval > 0
		noautocmd call asclib#window_goto_uid(retval)
	endif
	call asclib#window_goto_uid(uid)
	return retval
endfunc


"----------------------------------------------------------------------
" search buftype and filetype
"----------------------------------------------------------------------
function! asclib#window_search(buftype, filetype, modifiable)
	for i in range(winnr('$'))
		if getwinvar(i + 1, '&buftype') == a:buftype 
			if getwinvar(i + 1, '&filetype') == a:filetype
				if getwinvar(i + 1, '&modifiable') == a:modifiable
					return i + 1
				endif
			endif
		endif
	endfor
	return 0
endfunc


"----------------------------------------------------------------------
" preview window
"----------------------------------------------------------------------
if !exists('g:asclib#preview_position')
	let g:asclib#preview_position = "right"
endif

if !exists('g:asclib#preview_vsize')
	let g:asclib#preview_vsize = 0
endif

if !exists('g:asclib#preview_size')
	let g:asclib#preview_size = 0
endif


" check preview window is open ?
function! asclib#preview_check()
	for i in range(winnr('$'))
		if getwinvar(i + 1, '&previewwindow', 0)
			return asclib#window_uid('%', i + 1)
		endif
	endfor
	return 0
endfunc


" open preview vertical or horizon
function! asclib#preview_open()
	let pid = asclib#preview_check()
	if pid == 0
		let uid = asclib#window_uid('%', '%')
		let pos = g:asclib#preview_position
		let size = g:asclib#preview_vsize
		if pos == 'top' || pos == 'bottom' || pos == '0' || pos == '1'
			let size = g:asclib#preview_size
		endif
		let avoid = ['quickfix', 'help', 'nofile']
		let pid = asclib#window_new(pos, size, avoid)
		if pid > 0
			noautocmd call asclib#window_goto_uid(pid)
			set previewwindow
		endif
		noautocmd call asclib#window_goto_uid(uid)
	endif
	return pid
endfunc

" close preview window
function! asclib#preview_close()
	silent pclose
endfunc

" echo error message
function! asclib#errmsg(msg)
	redraw | echo '' | redraw
	echohl ErrorMsg
	echom a:msg
	echohl NONE
endfunc

" echo cmdline message
function! asclib#cmdmsg(content, highlight)
	let saveshow = &showmode
	set noshowmode
    let wincols = &columns
    let statusline = (&laststatus==1 && winnr('$')>1) || (&laststatus==2)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    let width = len(a:content)
    let limit = wincols - reqspaces_lastline
	let l:content = a:content
	if width + 1 > limit
		let l:content = strpart(l:content, 0, limit - 1)
		let width = len(l:content)
	endif
	" prevent scrolling caused by multiple echo
	redraw 
	if a:highlight != 0
		echohl Type
		echo l:content
		echohl NONE
	else
		echo l:content
	endif
	if saveshow != 0
		set showmode
	endif
endfunc


"----------------------------------------------------------------------
" taglist
"----------------------------------------------------------------------
function! asclib#taglist(pattern)
    let ftags = []
    try
        let ftags = taglist(a:pattern)
    catch /^Vim\%((\a\+)\)\=:E/
        " if error occured, reset tagbsearch option and try again.
        let bak = &tagbsearch
        set notagbsearch
        let ftags = taglist(a:pattern)
        let &tagbsearch = bak
    endtry
    return ftags
endfunc


"----------------------------------------------------------------------
" easy tagname
"----------------------------------------------------------------------
function! asclib#tagfind(tagname)
	let pattern = escape(a:tagname, '[\*~^')
	let result = asclib#taglist("^". pattern . "$")
	if type(result) == 0 || (type(result) == 3 && result == [])
		if pattern !~ '^\(catch\|if\|for\|while\|switch\)$'
			let result = asclib#taglist('::'. pattern .'$')
		endif
	endif
	if type(result) == 0 || (type(result) == 3 && result == [])
		return []
	endif
	return result
endfunc


"----------------------------------------------------------------------
" preview word highlight
"----------------------------------------------------------------------
hi previewWord term=bold ctermbg=green ctermfg=black guibg=green guifg=black


"----------------------------------------------------------------------
" display matched tag in the preview window
"----------------------------------------------------------------------
function! asclib#preview_tag(tagname)
	if &previewwindow
		return 0
	endif
	let uid = asclib#window_uid('%', '%')
	let pid = asclib#preview_check()
	let opt = {"tagname":""}
	let varname = 'asclib_preview_tag_cache'
	let reuse = 0
	let index = 0
	if pid > 0
		let [l:tabnr, l:winnr] = asclib#window_find(pid)
		let saveopt = gettabwinvar(l:tabnr, l:winnr, varname)
		if type(saveopt) == type({})
			let l:tagname = get(saveopt, 'tagname', '')
			if l:tagname == a:tagname
				let opt = saveopt
				let reuse = 1
			endif
		endif
	endif
	if reuse == 0
		let opt.tagname = a:tagname
		let opt.taglist = asclib#tagfind(a:tagname)
		let opt.index = 0
		if len(opt.taglist) > 0 && pid > 0
			call settabwinvar(l:tabnr, l:winnr, varname, opt)
		endif
	else
		let opt.index += 1
		if opt.index >= len(opt.taglist)
			let opt.index = 0
		endif
	endif
	if len(opt.taglist) == 0 
		call asclib#errmsg('E257: asclib: tag not find "'. a:tagname.'"')
		return 1
	endif
	if opt.index >= len(opt.taglist)
		call asclib#errmsg('E257: asclib: index error')
		return 2
	endif
	let taginfo = opt.taglist[opt.index]
	let filename = taginfo.filename
	if !filereadable(filename)
		call asclib#errmsg('E484: Can not open file '.filename)
		return 3
	endif
	if pid == 0
		let pid = asclib#preview_open()
		let [l:tabnr, l:winnr] = asclib#window_find(pid)
	endif
	call settabwinvar(l:tabnr, l:winnr, varname, opt)
	call asclib#window_goto_uid(uid)
	if 0
		let saveview = winsaveview()
		silent exec 'pedit '.fnameescape(filename)
		call winrestview(saveview)
		call asclib#window_goto_tabwin(l:tabnr, l:winnr)
	else
		call asclib#window_saveview()
		call asclib#window_goto_tabwin(l:tabnr, l:winnr)
		silent exec 'e! '.fnameescape(filename)
		call asclib#window_loadview()
	endif
	if &previewwindow
		match none
	endif
	normal! gg
	if has_key(taginfo, 'line')
		silent! exec "".taginfo.line
	else
		silent! exec "1"
		silent! exec taginfo.cmd
	endif
	if has("folding")
		silent! .foldopen!
	endif
	normal! zz
	let height = winheight('%') / 4
	if height >= 2
		silent! exec 'normal! '.height."\<c-e>"
	endif
	if 1
		call search("$", "b")
		call search(escape(a:tagname, '[\*~^'))
		exe 'match previewWord "\%' . line(".") . 'l\%' . col(".") . 'c\k*"'
	endif
	call asclib#window_goto_uid(uid)
	let text = taginfo.name
	let text.= ' ('.(opt.index + 1).'/'.len(opt.taglist).') '
	let text.= filename
	call asclib#cmdmsg(text, 1)
endfunc


"----------------------------------------------------------------------
" display preview file
"----------------------------------------------------------------------
function! asclib#preview_edit(bufnr, filename, line)
	let uid = asclib#window_uid('%', '%')
	let pid = asclib#preview_open()
	let [l:tabnr, l:winnr] = asclib#window_find(pid)
	call asclib#window_goto_tabwin(l:tabnr, l:winnr)
	call asclib#window_saveview()
	if a:bufnr <= 0
		silent exec "e! ".fnameescape(a:filename)
	else
		if winbufnr('%') != a:bufnr
			silent exec "b! ".a:bufnr
		endif
	endif
	call asclib#window_loadview()
	if a:line > 0
		noautocmd exec "".a:line
		if has('folding')
			silent! .foldopen!
		endif
		noautocmd exec "normal! zz"
		let height = winheight('%') / 4
		if height >= 2
			noautocmd exec "normal! ".height."\<c-e>"
		endif
		if &previewwindow
			match none
			exec 'match previewWord "\%'. a:line.'l"'
		endif
	endif
	call asclib#window_goto_uid(uid)
endfunc


"----------------------------------------------------------------------
" goto preview file
"----------------------------------------------------------------------
function! asclib#preview_goto(mode)
	let uid = asclib#window_uid('%', '%')
	let pid = asclib#preview_check()
	if pid == 0 || &previewwindow != 0 || uid == pid
		exec "norm! \<esc>"
		return
	endif
	if index(['quickfix', 'help', 'nofile'], &buftype) >= 0
		if a:mode == '' || a:mode == '0' || a:mode == '!'
			exec "norm! \<esc>"
			return
		endif
	endif
	let [l:tabnr, l:winnr] = asclib#window_find(pid)
	silent! wincmd P
	let l:bufnr = winbufnr(l:winnr)
	let l:bufname = bufname(l:bufnr)
	let l:line = line('.')
	call asclib#window_goto_uid(uid)
	if a:mode == '' || a:mode == '0'
		if l:bufnr != winbufnr('%')
			silent exec 'e '.fnameescape(l:bufname)
		endif
	elseif a:mode == '!'
		if l:bufnr != winbufnr('%')
			silent exec 'e! '.fnameescape(l:bufname)
		endif
	elseif a:mode == 'tab'
		silent exec 'tabe '. fnameescape(l:bufname)
	endif
	if winbufnr('%') == l:bufnr
		silent exec ''.l:line
		silent normal! zz
		let height = winheight('%') / 4
		if height >= 2
			exec "normal! ".height."\<c-e>"
		endif
	endif
endfunc


"----------------------------------------------------------------------
" display quickfix item in preview
"----------------------------------------------------------------------
function! asclib#preview_quickfix(linenr)
	let linenr = (a:linenr > 0)? a:linenr : line('.')
	let qflist = getqflist()
	if linenr < 1 || linenr > len(qflist)
		exec "norm! \<esc>"
		return ""
	endif
	let entry = qflist[linenr - 1]
	unlet qflist
	if entry.valid
		if entry.bufnr > 0
			call asclib#preview_edit(entry.bufnr, '', entry.lnum)
			let text = 'Preview: '.bufname(entry.bufnr)
			let text.= ' ('.entry.lnum.')'
			call asclib#cmdmsg(text, 1)
		else
			exec "norm! \<esc>"
		endif
	else
		exec "norm! \<esc>"
	endif
	return ""
endfunc


"----------------------------------------------------------------------
" switch to buffer
"----------------------------------------------------------------------
function! asclib#buffer_switch(bufnr, filename, linenr, position)
	let l:filename = (a:filename != '')? fnamemodify(a:filename, ':p') : ''
	for i in range(tabpagenr('$'))
		let l:buflist = tabpagebuflist(i + 1)
		for j in range(len(l:buflist))
			let l:bufnr = l:buflist[j]
			if !getbufvar(l:bufnr, '&modifiable')
				continue
			endif
			let l:buftype = getbufvar(l:bufnr, '&buftype')
			if l:buftype == 'quickfix' || l:buftype == 'nofile'
				continue
			endif
			let l:name = fnamemodify(bufname(l:bufnr), ':p')
			let l:compare = l:filename
			if has('win32') || has('win16') || has('win95') || has('win64')
				let l:name = tolower(l:name)
				let l:name = substitute(l:name, "\\", '/', 'g')
				let l:compare = tolower(l:filename)
				let l:compare = substitute(l:compare, "\\", '/', 'g')
			endif
			if (a:bufnr > 0 && a:bufnr == l:bufnr) || l:name == l:compare
				silent exec 'tabn '.(i + 1)
				silent exec ''.(j + 1).'wincmd w'
				if a:linenr > 0
					silent exec ''.a:linenr
				endif
				return
			endif
		endfor
	endfor
	let avoid = ['quickfix', 'nofile', 'help']
	if a:position != 'self' || index(avoid, &buftype) >= 0
		if a:position != 'tab'
			let uid = asclib#window_new(a:position, -1, avoid)
			call asclib#window_goto_uid(uid)
		else
			silent exec 'tabnew'
		endif
	endif
	if a:bufnr <= 0
		silent exec "e! ".fnameescape(a:filename)
	else
		if winbufnr('%') != a:bufnr
			silent exec "b! ". a:bufnr
		endif
	endif
	if a:linenr > 0
		silent exec ''.a:linenr
	endif
endfunc


"----------------------------------------------------------------------
" quickfix_switch
"----------------------------------------------------------------------
function! asclib#quickfix_switch(linenr, position)
	let qflist = getqflist()
	let linenr = (a:linenr > 0)? a:linenr : line('.')
	if linenr < 1 || linenr > len(qflist)
		exec "norm! \<esc>"
		return
	endif
	let entry = qflist[linenr - 1]
	unlet qflist
	if entry.valid
		if entry.bufnr > 0
			call asclib#buffer_switch(entry.bufnr, '', entry.lnum, a:position)
			let text = 'Switch: '.bufname(entry.bufnr)
			let text.= ' ('.entry.lnum.')'
			call asclib#cmdmsg(text, 1)
		else
			exec "norm! \<esc>"
		endif
	else
		exec "norm! \<esc>"
	endif
endfunc



"----------------------------------------------------------------------
" path basic
"----------------------------------------------------------------------
let s:scriptname = expand('<sfile>:p')
let s:scripthome = fnamemodify(s:scriptname, ':h')
let s:windows = (has('win95') || has('win32') || has('win64') || has('win16'))

" join path
function! asclib#path_join(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
    let l:last = strpart(a:home, l:size - 1, 1)
    if has("win32") || has("win64") || has("win16") || has('win95')
        if l:last == "/" || l:last == "\\"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    else
        if l:last == "/"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    endif
endfunc

" path asc home
function! asclib#path_runtime(path)
	let pathname = fnamemodify(s:scripthome, ':h')
	let pathname = asclib#path_join(pathname, a:path)
	let pathname = fnamemodify(pathname, ':p')
	return substitute(pathname, '\\', '/', 'g')
endfunc

" find files in path
function! asclib#path_which(name)
	if has('win32') || has('win64') || has('win16') || has('win95')
		let sep = ';'
	else
		let sep = ':'
	endif
	for path in split($PATH, sep)
		let filename = asclib#path_join(path, a:name)
		if filereadable(filename)
			return vimmake#fullname(filename)
		endif
	endfor
	return ''
endfunc

" find executable
function! asclib#path_executable(name)
	if s:windows != 0
		for n in ['', '.exe', '.cmd', '.bat', '.vbs']
			let nname = a:name . n
			let npath = asclib#path_which(nname)
			if npath != ''
				return npath
			endif
		endfor
	else
		return asclib#path_which(a:name)
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" function signature
"----------------------------------------------------------------------
function! asclib#function_signature(funname, fn_only, filetype)
	let tags = asclib#tagfind(a:funname)
    let funpat = escape(a:funname, '[\*~^')
	let fill_tag = []
	let ft = (a:filetype == '')? &filetype : a:filetype
	for i in tags
		if !has_key(i, 'name')
			continue
		endif
		if has_key(i, 'language')
		endif
		if has_key(i, 'filename') && ft != '*'
			let ename = tolower(fnamemodify(i.filename, ':e'))
			let c = ['c', 'cpp', 'cc', 'cxx', 'h', 'hpp', 'hh', 'm', 'mm']
			if index(['c', 'cpp', 'objc', 'objcpp'], ft) >= 0
				if index(c, ename) < 0
					continue
				endif
			elseif ft == 'python'
				if index(['py', 'pyw'], ename) < 0
					continue
				endif
			elseif ft == 'java' && ename != 'java'
				continue
			elseif ft == 'ruby' && ename != 'rb'
				continue
			elseif ft == 'vim' && ename != 'vim'
				continue
			elseif ft == 'cs' && ename != 'cs'
				continue
			elseif ft == 'php' 
				if index(['php', 'php4', 'php5', 'php6'], ename) < 0
					continue
				endif
			elseif ft == 'javascript'
				if index(['html', 'js', 'html5', 'xhtml', 'php'], ename) < 0
					continue
				endif
			endif
		endif
		if has_key(i, 'kind')
			" p: prototype/procedure; f: function; m: member
			if (a:fn_only == 0 || (i.kind == 'p' || i.kind == 'f') ||
						\ (i.kind == 'm' && has_key(i, 'cmd') &&
						\		match(i.cmd, '(') != -1)) &&
						\ i.name =~ funpat
				if ft != 'cpp' || !has_key(i, 'class') ||
							\ i.name !~ '::' || i.name =~ i.class
					let fill_tag += [i]
				endif
			endif
		else
			if a:fn_only == 0 && i.name == a:funname
				let fill_tag += [i]
			endif
		endif
	endfor
	let res = []
	let index = 1
	for i in fill_tag
		if has_key(i, 'kind') && has_key(i, 'signature')
			if i.cmd[:1] == '/^' && i.cmd[-2:] == '$/'
				let tmppat = substitute(escape(i.name,'[\*~^'),
							\ '^.*::','','')
				if ft == 'cpp'
					let tmppat = substitute(tmppat,'\<operator ',
								\ 'operator\\s*','')
					let tmppat=tmppat . '\s*(.*'
					let tmppat='\([A-Za-z_][A-Za-z_0-9]*::\)*'.tmppat
				else
					let tmppat=tmppat . '\>.*'
				endif
				let name = substitute(i.cmd[2:-3],tmppat,'','').
							\ i.name . i.signature
                if i.kind == 'm'
                    if has_key(i, 'class')
                        let name = name . ' <-- class ' . i.class
                    elseif has_key(i, 'struct')
                        let name = name . ' <-- struct ' . i.struct
                    elseif has_key(i, 'union')
                        let name = name . ' <-- union ' . i.union
                    endif
                endif
			else
				let name = i.name . i.signature
				if has_key(i, 'kind') && match('fm', i.kind) >= 0
					let sep = (ft == 'cpp' || ft == 'c')? '::' : '.'
					if has_key(i, 'class')
						let name = i.class . sep . name
					elseif has_key(i, 'struct')
						let name = i.struct . sep. name
					elseif has_key(i, 'union')
						let name = i.struct . sep. name
					endif
				endif
			endif
		elseif has_key(i, 'kind')
			if i.kind == 'd'
				let name = 'macro '. i.name
			elseif i.kind == 'c'
				let name = ((ft == 'vim')? 'command ' : 'class '). i.name
			elseif i.kind == 's'
				let name = 'struct '. i.name
			elseif i.kind == 'u'
				let name = 'union '. i.name
			elseif (match('fpmvt', i.kind) != -1) &&
						\(has_key(i, 'cmd') && i.cmd[0] == '/')
				let tmppat = '\(\<'.i.name.'\>.\{-}\)'
				if index(['c', 'cpp', 'cs', 'java', 'javascript'], ft) >= 0
					let tmppat = tmppat . ';.*'
				elseif ft == 'python' && (i.kind == 'm' || i.kind == 'f')
					let tmppat = tmppat . ':.*'
				elseif ft == 'tcl' && (i.kind == 'm' || i.kind == 'p')
					let tmppat = tmppat . '\({\)\?$'
				endif
                if i.kind == 'm' && &filetype == 'cpp'
                    let tmppat=substitute(tmppat,'^\(.*::\)','\\(\1\\)\\?','')
                endif
                if match(i.cmd[2:-3], tmppat) != -1
                    let name=substitute(i.cmd[2:-3], tmppat, '\1', '')
                    if i.kind == 't' && name !~ '^\s*typedef\>'
                        let name = 'typedef ' . i.name
                    endif
                elseif i.kind == 't'
                    let name = 'typedef ' . i.name
                elseif i.kind == 'v'
                    let name = 'var ' . i.name
                else
                    let name = i.name
                endif
                if i.kind == 'm'
                    if has_key(i, 'class')
                        let name = name . ' <-- class ' . i.class
                    elseif has_key(i, 'struct')
                        let name = name . ' <-- struct ' . i.struct
                    elseif has_key(i, 'union')
                        let name = name . ' <-- union ' . i.union
                    endif
                endif
			else
				let name = i.name
			endif
		else
			let name = i.name
		endif
		let name = substitute(name, '^\s\+', '', '')
		let name = substitute(name, '\s\+$', '', '')
		let name = substitute(name, '\s\+', ' ', 'g')
		let file_line = ''
		if has_key(i, 'filename')
			let file_line = fnamemodify(i.filename, ':t')
			if has_key(i, 'line')
				let file_line .= ':'. i.line
			elseif i.cmd > 0
				let file_line .= ':'. i.cmd
			endif
		endif
		let desc = name. ' ('.index.'/'.len(fill_tag).') '.file_line
		let res += [desc]
		let index += 1
	endfor
	return res
endfunc


"----------------------------------------------------------------------
" function name normalize
"----------------------------------------------------------------------

" get function name
function! asclib#function_name(text)
    let name = substitute(a:text,'.\{-}\(\(\k\+::\)*\(\~\?\k*\|'.
                \'operator\s\+new\(\[]\)\?\|'.
                \'operator\s\+delete\(\[]\)\?\|'.
                \'operator\s*[[\]()+\-*/%<>=!~\^&|]\+'.
                \'\)\)\s*$','\1','')
    if name =~ '\<operator\>'  " tags have exactly one space after 'operator'
        let name = substitute(name,'\<operator\s*','operator ','')
    endif
    return name
endfunc

" guess function names
function! asclib#function_guess(text)
	let size = len(a:text)
	while size > 0
		if index(['(', ')', ',', ' ', "\t"], a:text[size - 1]) >= 0
			let size -= 1
		else
			break
		endif
	endwhile
	let limit = (size == 0)? 0 : size - 1
	return asclib#function_name(a:text[0:limit])
endfunc


"----------------------------------------------------------------------
" function next 
"----------------------------------------------------------------------
function! asclib#function_prototype(funcname, filetype)
	let ft = (a:filetype == '')? &filetype : a:filetype
	if !exists('w:asclib_prototype_cache')
		let w:asclib_prototype_cache = { 'name': '', 'index': 0, 'data': [] }
		let w:asclib_prototype_cache.ft = ''
	endif
	let proto = w:asclib_prototype_cache
	if proto.name != a:funcname || proto.ft != ft
		let res = asclib#function_signature(a:funcname, 0, ft)
		let proto.data = res
		let proto.index = 0
		let proto.name = a:funcname
		let proto.ft = ft
		let w:asclib_prototype_cache = proto
	endif
	if len(proto.data) == 0
		unlet w:asclib_prototype_cache
		return ''
	endif
	let text = proto.data[proto.index]
	let text = substitute(text, '^\s*', '', '')
	let proto.index += 1
	if proto.index >= len(proto.data)
		let proto.index = 0
		unlet w:asclib_prototype_cache
	endif
	return text
endfunc


"----------------------------------------------------------------------
" prototype 
"----------------------------------------------------------------------
function! asclib#function_define()
	let line = getline('.')
	let pos = col('.') - 1
	let endpos = match(line, '\W', pos)
	if endpos != -1 && &filetype == 'cpp'
		let word = expand('<cword>')
		if word == 'operator'
			if line[endpos:] =~ '^\s*\(new\(\[]\)\?\|delete\(\[]\)\?\|[[\]'
						\.'+\-*/%<>=!~\^&|]\+\|()\)'
				let endpos = matchend(line, '^\s*\(new\(\[]\)\?\|delete\(\['
							\.']\)\?\|[[\]+\-*/%<>=!~\^&|]\+\|()\)', endpos)
			endif
		elseif word == 'new' || word == 'delete'
            if line[:endpos + 1] =~ 'operator\s\+\(new\|delete\)\[]$'
				let endpos = endpos + 2
			endif
		endif
	endif
	if endpos != -1
		let endpos = endpos - 1
	endif
	let name = asclib#function_guess(line[0:endpos])
	if name == ''
		return ''
	endif
	return asclib#function_prototype(name, &filetype)
endfunc

" function preview
function! asclib#function_echo(nosc)
	let text = asclib#function_define()
	if text == ''
		return ''
	endif
	if a:nosc != 0
		set noshowmode
	endif
	"call asclib#miniwin_display(text)
	call asclib#cmdmsg(text, 1)
	return ''
endfunc



"----------------------------------------------------------------------
" miniwin_name
"----------------------------------------------------------------------
function! asclib#miniwin_name() abort
	if !exists('s:buffer_seqno')
		let s:buffer_seqno = 0
	endif
    if !exists('t:asclib_miniwin_buf_name')
        let s:buffer_seqno += 1
        let t:asclib_miniwin_buf_name = '__MiniWin__.' . s:buffer_seqno
    endif
    return t:asclib_miniwin_buf_name
endfunc


"----------------------------------------------------------------------
" open mini window below the tagbar
"----------------------------------------------------------------------
function! asclib#miniwin_toggle()
	let mark_win = asclib#window_search('quickfix', 'qf', 0)
	let mini_win = asclib#window_search('nofile', 'miniwin', 0)
	if mark_win == 0
		if mini_win > 0
			let uid = asclib#window_uid('%', '%')
			silent! exec ''.mini_win.'wincmd w'
			silent! close
			if exists('t:asclib_miniwin')
				unlet t:asclib_miniwin
			endif
			call asclib#window_goto_uid(uid)
		endif
	else
		let height = get(g:, 'asclib_miniwin_height', 10)
		let width = get(g:, 'asclib_miniwin_width', 80)
		let mark_uid = asclib#window_uid('%', mark_win)
		if mini_win == 0
			let uid = asclib#window_uid('%', '%')
			silent! exec ''.mark_win.'wincmd w'
			let view = winsaveview()
			exec "vs ".asclib#miniwin_name()
			"exec 'belowright '.height.'split '.asclib#miniwin_name()
			setlocal buftype=nofile 
			setlocal filetype=miniwin
			setlocal nomodifiable
			setlocal nonumber
			setlocal signcolumn=no
			setlocal statusline=[miniwin]
			setlocal wrap
			call asclib#window_goto_uid(mark_uid)
			call winrestview(view)
			call asclib#window_goto_uid(uid)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" asclib#miniwin_display
"----------------------------------------------------------------------
function! asclib#miniwin_display(string)
	let wid = asclib#window_search('nofile', 'miniwin', 0)
	if wid == 0
		return
	endif
	let uid = asclib#window_uid('%', '%')
	let xid = asclib#window_uid('%', wid)
	noautocmd call asclib#window_goto_uid(xid)
	let save = @0
	setlocal modifiable
	silent exec "normal! ggVGx"
	let @" = a:string
	silent exec "normal! ggPgg"
	let @" = save
	setlocal nomodifiable
	noautocmd call asclib#window_goto_uid(uid)
endfunc


"----------------------------------------------------------------------
" toggle tagbar and miniwin together
"----------------------------------------------------------------------
function! asclib#miniwin_quickfix_toggle()
	silent call vimmake#toggle_quickfix(6)
	silent call asclib#miniwin_toggle()
endfunc


"----------------------------------------------------------------------
" lint - 
"----------------------------------------------------------------------

" python - pylint
function! asclib#lint_pylint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path_runtime('tools/conf/pylint.conf') 
	let cmd = 'pylint --rcfile='.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc

" python - flake8
function! asclib#lint_flake8(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path_runtime('tools/conf/flake8.conf') 
	let cmd = 'flake8 --config='.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc

" c/c++ - cppcheck
function! asclib#lint_cppcheck(filename)
	if !exists('g:asclib#lint_cppcheck_parameters')
		let g:asclib#lint_cppcheck_parameters = '--library=windows'
		let g:asclib#lint_cppcheck_parameters.= ' --quiet'
		let g:asclib#lint_cppcheck_parameters.= ' --enable=warning'
		let g:asclib#lint_cppcheck_parameters.= ',performance,portability'
		let g:asclib#lint_cppcheck_parameters.= ' -DWIN32 -D_WIN32'
	endif
	let filename = (a:filename == '')? expand('%') : a:filename
	let cfg = g:asclib#lint_cppcheck_parameters
	let cmd = 'cppcheck '.cfg.' '.shellescape(filename)
	call vimmake#run('', {'auto':'make'}, cmd)
endfunc

" c - splint
function! asclib#lint_splint(filename)
	let filename = (a:filename == '')? expand('%') : a:filename
	let rc = asclib#path_runtime('tools/conf/splint.conf') 
	let cmd = 'splint -f '.shellescape(rc).' '.shellescape(filename)
	let opt = {'auto': "make"}
	call vimmake#run('', opt, cmd)
endfunc


"----------------------------------------------------------------------
" open something
"----------------------------------------------------------------------
let s:config = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')

" call winhlp32.exe to open .hlp
function! asclib#open_win32_help(hlp, keyword)
	if !filereadable(a:hlp)
		call asclib#errmsg('can not open: '.a:hlp)
		return 1
	endif
	if asclib#path_which('winhlp32.exe') == ''
		call asclib#errmsg('can not find WinHlp32.exe, please install it')
		return 2
	endif
	if executable('python')
		let path = s:config
		let cmd = 'python '
		let cmd .= path . '/lib/vimhelp.py -h '.shellescape(a:hlp)
		if a:keyword != ''
			let cmd .= ' ' . shellescape(a:keyword)
		endif
		exec 'VimMake -mode=5 '.cmd
		return 0
	endif
	let cmd = 'WinHlp32.exe '
	if a:keyword != ''
		let kw = split(a:keyword, ' ')[0]
		if kw != ''
			let cmd .= '-k '.kw. ' '
		endif
	endif
	exec 'VimMake -mode=5 '.cmd. shellescape(a:hlp)
	return 0
endfunc


function! asclib#open_win32_chm(chm, keyword)
	if !filereadable(a:chm)
		call asclib#errmsg('can not open: '.a:chm)
		return 1
	endif
	if a:keyword == ''
		silent exec 'VimMake -mode=5 '.shellescape(a:chm)
		return 0
	else
		if asclib#path_which('KeyHH.exe') == ''
			call asclib#errmsg('can not find KeyHH.exe, please install it')
			return 2
		endif
	endif
	let chm = shellescape(a:chm)
	let cmd = 'KeyHH.exe -\#klink '.shellescape(a:keyword).' '.chm
	silent exec '!start /b '.cmd
endfunc


"----------------------------------------------------------------------
" smooth interface
"----------------------------------------------------------------------
function! s:smooth_scroll(dir, dist, duration, speed)
	for i in range(a:dist/a:speed)
		let start = reltime()
		if a:dir ==# 'd'
			exec 'normal! '. a:speed."\<C-e>".a:speed."j"
		else
			exec 'normal! '. a:speed."\<C-y>".a:speed."k"
		endif
		redraw
		let elapsed = s:get_ms_since(start)
		let snooze = float2nr(a:duration - elapsed)
		if snooze > 0
			exec "sleep ".snooze."m"
		endif
	endfor
endfunc

function! s:get_ms_since(time)
	let cost = split(reltimestr(reltime(a:time)), '\.')
	return str2nr(cost[0]) * 1000 + str2nr(cost[1]) / 1000.0
endfunc

function! asclib#smooth_scroll_up(dist, duration, speed)
	call s:smooth_scroll('u', a:dist, a:duration, a:speed)
endfunc

function! asclib#smooth_scroll_down(dist, duration, speed)
	call s:smooth_scroll('d', a:dist, a:duration, a:speed)
endfunc


"----------------------------------------------------------------------
" gprof
"----------------------------------------------------------------------
function! asclib#open_gprof(image, profile)
	let l:image = a:image
	let l:profile = a:profile
	if asclib#path_executable('gprof') == ''
		call s:errmsg('cannot find gprof')
		return
	endif
	if l:image == ''
		let l:image = expand("%:p:h") . '/' . expand("%:t:r") 
		let l:image.= s:windows? '.exe' : ''
		if l:profile == ''
			let l:profile = expand("%:p:h") . '/gmon.out'
		endif
	elseif l:profile == ''
		let l:profile = 'gmon.out'
	endif
	let command = 'gprof '.shellescape(l:image).' '.shellescape(l:profile)
	let text = vimmake#python_system(command)
	let text = substitute(text, '\r', '', 'g')
	vnew
	let l:save = @0
	let @0 = text
	normal! "0P
	let @0 = l:save
	setlocal buftype=nofile bufhidden=delete nobuflisted nomodifiable
	setlocal noshowcmd noswapfile nowrap nonumber signcolumn=no nospell
	setlocal fdc=0 nolist colorcolumn= nocursorline nocursorcolumn
	setlocal noswapfile norelativenumber
	setlocal filetype=gprof
endfunc


"----------------------------------------------------------------------
" execute scripts in string
"----------------------------------------------------------------------
function! asclib#eval_text(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let result = eval(script)
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc


"----------------------------------------------------------------------
" ask text
"----------------------------------------------------------------------
function! asclib#input_text(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let varname = script
			let default = ""
			let pos = stridx(script, '=')
			if pos >= 0
				let varname = strpart(script, 0, pos)
				let default = strpart(script, pos + 1)
			endif
			if varname == ''
				if default != ''
					let result = eval(devault)
				endif
			else
				redraw
				let result = input('input ('.varname.'): ', default)
				redraw
				if result == ''
					return ''
				endif
			endif
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc


"----------------------------------------------------------------------
" string & config
"----------------------------------------------------------------------

function! asclib#string_strip(text)
	return substitute(a:text, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunc

function! asclib#decode_cfg(string) abort
	let item = {}
	if type(a:string) == type('')
		let data = split(a:string, "\n")
	else
		let data = a:string
	endif
	for curline in data
		let pos = stridx(curline, ':')
		if pos <= 0
			continue
		endif
		let name = asclib#string_strip(strpart(curline, 0, pos))
		let data = asclib#string_strip(strpart(curline, pos + 1))
		if name == ''
			continue
		endif
		let item[name] = data
	endfor
	return item
endfunc

function! asclib#encode_cfg(item) 
	let output = []
	for name in keys(a:item)
		let data = a:item[name]
		let name = substitute(name, '[\n\r]', '', 'g')
		let data = substitute(data, '[\n\r]', '', 'g')
		let output += [name . ': ' . data]
	endfor
	return join(output, "\n")
endfunc

function! asclib#read_cfg(filename)
	let filename = a:filename
	if stridx(filename, '~') >= 0
		let filename = expand(filename)
	endif
	let data = readfile(filename)
	return asclib#decode_cfg(data)
endfunc

function! asclib#write_cfg(filename, item) abort
	let filename = a:filename
	if stridx(filename, '~') >= 0
		let filename = expand(filename)
	endif
	let data = asclib#encode_cfg(a:item)
	call writefile(split(data, "\n"), filename)
endfunc


"----------------------------------------------------------------------
" snips
"----------------------------------------------------------------------

function! asclib#snip_insert(text, mode)
	let text = asclib#input_text(a:text)
	if text == ''
		return ""
	endif
	if stridx(text, '@') < 0
		let text .= '@'
	endif
	let save = @z
	let @z = text
	silent exec 'normal! "z]p'
	let @z = save
	call search('@')
	if a:mode == 0
		call feedkeys('s', 'm')
	else
		call feedkeys("\<del>", "m")
	endif
	return ""
endfunc



"----------------------------------------------------------------------
" find and touch a file (usually a wsgi file)
"----------------------------------------------------------------------
function! asclib#touch_file(name)
	if has('win32') || has('win64') || has('win16') || has('win95')
		echo 'touching is not supported on windows'
		return
	endif
	let l:filename = findfile(a:name, '.;')
	if l:filename == ''
		echo 'not find: "'.a:name .'"'
	else
		call system('touch ' . shellescape(l:filename) . ' &')
		echo 'touch: '. l:filename
	endif
endfunc


"----------------------------------------------------------------------
" prettify html
"----------------------------------------------------------------------
function! asclib#html_prettify()
	if &ft != 'html'
		echo "not a html file"
		return
	endif
	silent! exec "s/<[^>]*>/\r&\r/g"
	silent! exec "g/^$/d"
	exec "normal ggVG="
endfunc



"----------------------------------------------------------------------
" owncloud
"----------------------------------------------------------------------
if !exists('g:asclib#owncloud')
	let g:asclib#owncloud = ['', '', '']
endif

if !exists('g:asclib#owncloudcmd')
	let g:asclib#owncloudcmd = ''
endif


function! asclib#owncloud_call(command)
	let cmd = g:asclib#owncloudcmd
	if cmd == ''
		let cmd = asclib#path_executable('owncloudcmd')
	endif
	if cmd == '' && s:windows != 0
		if filereadable('C:/Program Files (x86)/ownCloud/owncloudcmd.exe')
			let cmd = 'C:/Program Files (x86)/ownCloud/owncloudcmd.exe'
		elseif filereadable('C:/Program Files/ownCloud/owncloudcmd.exe')
			let cmd = 'C:/Program Files/ownCloud/owncloudcmd.exe'
		endif
	endif
	if cmd == ''
		call asclib#errmsg("cannot find owncloudcmd")		
		return
	endif
	call vimmake#run('', {}, shellescape(cmd) . ' ' . a:command)
endfunc


function! asclib#owncloud_sync()
	let cloud = expand('~/.vim/cloud')
	try
		silent call mkdir(cloud, "p", 0755)
	catch /^Vim\%((\a\+)\)\=:E/
	finally
	endtry
	if type(g:asclib#owncloud) != type([])
		call asclib#errmsg("bad g:asclib#owncloud config")
		return
	endif
	if len(g:asclib#owncloud) != 3
		call asclib#errmsg("bad g:asclib#owncloud config")
		return
	endif
	let url = g:asclib#owncloud[0]
	let cloud_user = g:asclib#owncloud[1]
	let cloud_pass = g:asclib#owncloud[2]
	if strpart(url, 0, 5) != 'http:' && strpart(url, 0, 6) != 'https:'
		call asclib#errmsg("bad g:asclib#owncloud[0] config")
		return
	endif
	if cloud_user == ''
		call asclib#errmsg("bad g:asclib#owncloud[1] config")
		return
	endif
	let cmd = '-u ' .shellescape(cloud_user) . ' '
	if cloud_pass
		let cmd .= '-p ' .shellescape(cloud_pass) . ' '
	endif
	let cmd .= '--trust --non-interactive '
	let cmd .= (s:windows == 0)? '--exclude /dev/null ' : ''
	let cmd .= shellescape(cloud) . ' ' . shellescape(url)
	call asclib#owncloud_call(cmd)
endfunc


function! asclib#show_rtp()
	for key in split(&rtp, ',')
		echo key
	endfor
endfunc


function! asclib#quickfix_title(title)
	if !has('nvim')
		if v:version >= 800 || has('patch-7.4.2210')
			call setqflist([], 'a', {'title': a:title})
			redrawstatus!
		else
			call setqflist([], 'a')
		endif
	else
		call setqflist([], 'a', a:title)
		redrawstatus!
	endif
endfunc


"----------------------------------------------------------------------
" bash for windows 
"----------------------------------------------------------------------
function! asclib#wsl_bash(cwd)
	let root = $SystemRoot
	let test1 = root . '/system32/bash.exe'
	let test2 = root . '/SysNative/bash.exe'
	let cd = haslocaldir()? 'lcd ' : 'cd '
	let cwd = getcwd()
	if executable(test1)
		let name = test1
	elseif executable(test2)
		let name = test2
	else
		call asclib#errmsg('can not find bash for window')
		return
	endif
	if a:cwd != ''
		if a:cwd == '%'
			exec cd . fnameescape(expand('%:p:h'))
		else
			exec cd . fnameescape(a:cwd)
		endif
	endif
	silent exec 'silent !start '. fnameescape(name)
	if a:cwd != ''
		exec cd . fnameescape(cwd)
	endif
endfunc


"----------------------------------------------------------------------
" change color
"----------------------------------------------------------------------
function! asclib#color_switch(names)
	if !exists('s:color_index')
		let s:color_index = 0
	endif
	if len(a:names) == 0
		return
	endif
	if s:color_index >= len(a:names)
		let s:color_index = 0
	endif
	let color = a:names[s:color_index]
	let s:color_index += 1
	exec 'color '.fnameescape(color)
	redraw! | echo "" | redraw!
	echo 'color '.color
endfunc


