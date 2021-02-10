"======================================================================
"
" window.vim - window manager
"
" Created by skywind on 2018/04/25
" Last Modified: 2018/04/25 04:44:41
"
"======================================================================

"----------------------------------------------------------------------
" window basic
"----------------------------------------------------------------------

" save all window's view
function! asclib#window#saveview()
	function! s:window_view_save()
		let w:asclib_window_view = winsaveview()
	endfunc
	let l:winnr = winnr()
	noautocmd windo call s:window_view_save()
	noautocmd silent! exec ''.l:winnr.'wincmd w'
endfunc

" restore all window's view
function! asclib#window#loadview()
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
function! asclib#window#uid(tabnr, winnr)
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
function! asclib#window#find(uid)
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
function! asclib#window#goto_tabwin(tabnr, winnr)
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
function! asclib#window#goto_uid(uid)
	let [l:tabnr, l:winnr] = asclib#window#find(a:uid)
	if l:tabnr == 0 || l:winnr == 0
		return 1
	endif
	call asclib#window#goto_tabwin(l:tabnr, l:winnr)
	return 0
endfunc

" new window and return window uid, zero for error
function! asclib#window#new(position, size, avoid)
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
	let uid = asclib#window#uid('%', '%')
	let retval = 0
	noautocmd windo call s:window_new_action(0)
	noautocmd call asclib#window#goto_uid(uid)
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
	let retval = asclib#window#uid('%', '%')
	noautocmd windo call s:window_new_action(1)
	if retval > 0
		noautocmd call asclib#window#goto_uid(retval)
	endif
	call asclib#window#goto_uid(uid)
	return retval
endfunc


"----------------------------------------------------------------------
" search buftype and filetype
"----------------------------------------------------------------------
function! asclib#window#search(buftype, filetype, modifiable)
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
" reposition window
"----------------------------------------------------------------------
function! asclib#window#up(color)
	if has('folding')
		silent! .foldopen!
	endif
	noautocmd exec "normal! zz"
	if &previewwindow && a:color != ''
		let xline = line('.')
		match none
		exec 'match '.a:color.' "\%'. xline.'l"'
	endif
	let height = winheight('%') / 4
	let winfo = winsaveview()
	let avail = line('.') - winfo.topline - &scrolloff
	let height = (height < avail)? height : avail
	if height > 0
		noautocmd exec "normal! ".height."\<c-e>"
	endif
endfunc


