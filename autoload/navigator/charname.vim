" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" charkey.vim - 
"
" Created by skywind on 2022/10/26
" Last Modified: 2024/02/22 22:19
"
"======================================================================

let s:special_names = {
			\ "\<esc>" : "<esc>",
			\ "\<space>" : "<space>",
			\ "\<cr>" : "<cr>",
			\ "\<tab>" : "<tab>",
			\ "\<bs>" : "<bs>",
			\ "\<Bar>": '<bar>',
			\ "\<Bslash>": '<Bslash>',
			\ "\<Up>": '<up>',
			\ "\<Down>": '<down>',
			\ "\<Left>": '<left>',
			\ "\<Right>": '<right>',
			\ "\<PageUp>" : '<PageUp>',
			\ "\<PageDown>" : '<PageDown>',
			\ "\<Home>" : '<home>',
			\ "\<End>" : '<end>',
			\ "\<Insert>" : '<insert>',
			\ "\<Del>" : '<del>',
			\ "\<LeftMouse>": '<LeftMouse>',
			\ "\<RightMouse>": '<RightMouse>',
			\ "\<MiddleMouse>": '<MiddleMouse>',
			\ "\<2-LeftMouse>": '<2-LeftMouse>',
			\ "\<C-LeftMouse>": '<C-LeftMouse>',
			\ "\<S-LeftMouse>": '<S-LeftMouse>',
			\ "\<ScrollWheelUp>": '<ScrollWheelUp>',
			\ "\<ScrollWheelDown>": '<ScrollWheelDown>',
			\ "\<C-Space>": '<C-Space>',
			\ "\<C-Left>": '<C-Left>',
			\ "\<C-Right>": '<C-Right>',
			\ "\<S-Left>": '<S-Left>',
			\ "\<S-Right>": '<S-Right>',
			\ }


let pending = []

for key in range(26)
	let pending += [nr2char(char2nr('a') + key)]
	let pending += [nr2char(char2nr('A') + key)]
endfor

for key in range(10)
	let pending += [nr2char(char2nr('0') + key)]
endfor

for i in range(12)
	let nn = i + 1
	let cc = eval('"\<f' . nn . '>"')
	let s:special_names[cc] = printf('<f%d>', nn)
endfor

for ch in pending
	let cc = eval('"\<c-' . ch . '>"')
	if !has_key(s:special_names, cc)
		let s:special_names[cc] = '<c-'. ch . '>'
	endif
	let cc = eval('"\<m-' . ch . '>"')
	let s:special_names[cc] = '<m-'. ch . '>'
	let s:special_names[ch] = ch
endfor

let pending = '!@#$%^&*-=_+;:,./?`~[]'

for i in range(strlen(pending))
	let ch = pending[i]
	let s:special_names[ch] = ch
endfor

let s:special_keys = {}

for key in keys(s:special_names)
	let ch = s:special_names[key]
	if len(ch) > 1
		let ch = tolower(ch)
	endif
	let s:special_keys[ch] = key
endfor

" echo keys(s:special_keys)

let s:char_display = {
			\ "<cr>" : "RET",
			\ "<space>" : "SPC",
			\ "<escape>" : "ESC",
			\ "<esc>" : "ESC",
			\ "<return>" : "RET",
			\ "<tab>" : "TAB",
			\ "<bs>" : "BSP", 
			\ "<home>" : "HOME", 
			\ "<end>" : "END", 
			\ "<pageup>" : "PGUP", 
			\ "<pagedown>" : "PGDN", 
			\ "<insert>" : "INS",
			\ "<del>" : "DEL",
			\ }

for i in range(12)
	let n = i + 1
	let s:char_display[printf('<f%d>', n)] = 'F' . n
endfor


"----------------------------------------------------------------------
" translate from key-name '<esc>' to key-code '\<esc>'
"----------------------------------------------------------------------
function! navigator#charname#get_key_code(key)
	let key = a:key
	if key == ''
		return ''
	elseif len(key) == 1
		if has_key(s:special_names, key)
			return key
		endif
	elseif stridx(key, '<') == 0
		let lowkey = tolower(key)
		if has_key(s:special_keys, key)
			return s:special_keys[key]
		elseif has_key(s:special_keys, lowkey)
			return s:special_keys[lowkey]
		endif
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get a proper key-name from key-code
"----------------------------------------------------------------------
function! navigator#charname#get_key_name(code)
	return get(s:special_names, a:code, '')
endfunc


"----------------------------------------------------------------------
" get key-label from key-name
"----------------------------------------------------------------------
function! navigator#charname#get_key_label(key)
	let code = navigator#charname#get_key_code(a:key)
	if code == ''
		return 'BADKEY'
	endif
	if !has_key(s:special_names, code)
		return 'BADKEY'
	endif
	let display = s:special_names[code]
	return get(get(g:, 'navigator_char_display', {}), tolower(display),
				\ get(s:char_display, tolower(display), display))
endfunc


"----------------------------------------------------------------------
" input a array of key-names and sort by their display-names
"----------------------------------------------------------------------
function! navigator#charname#sort(keys)
	let buckets = {}
	for key in a:keys
		let label = navigator#charname#get_key_label(key)
		if label == ''
			continue
		endif
		let size = len(label)
		if !has_key(buckets, size)
			let buckets[size] = []
		endif
		let buckets[size] += [[key, label]]
	endfor
	let names = keys(buckets)
	let result = []
	call sort(names, 'n')
	call reverse(names)
	for key in names
		let bucket = buckets[key]
		call sort(bucket, { i1, i2 -> (i1[1] > i2[1])? 1 : -1 })
		for item in bucket
			let result += [item[0]]
		endfor
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" replace string
"----------------------------------------------------------------------
function! s:replace(text, old, new)
	let l:data = split(a:text, a:old, 1)
	return join(l:data, a:new)
endfunc


"----------------------------------------------------------------------
" convert '<tab>hh' to "\<tab>hh"
"----------------------------------------------------------------------
function! navigator#charname#mapname(content) abort
	let content = a:content
	let output = []
	let pos = 0
	while 1
		let p1 = stridx(content, '<', pos)
		if p1 < 0
			call add(output, strpart(content, pos))
			break
		endif
		let p2 = stridx(content, '>', p1)
		if p2 < 0
			call add(output, strpart(content, pos))
			break
		endif
		let text = strpart(content, p1 + 1, p2 - p1 - 1)
		let mark = '<' . text . '>'
		let replace = mark
		if len(mark) > 2
			try
				let replace = eval('"\' . mark . '"')
			catch
			endtry
		endif
		call add(output, strpart(content, pos, p1 - pos))
		call add(output, replace)
		let pos = p2 + 1
	endwhile
	return join(output, '')
endfunc


"----------------------------------------------------------------------
" change '<space><space>' to 'SPC SPC'
"----------------------------------------------------------------------
function! navigator#charname#prefix_label(prefix) abort
	let part = []
	let prefix = a:prefix
	while len(prefix) > 0
		let ch = strpart(prefix, 0, 1)
		if ch == '<'
			let p1 = stridx(prefix, '>')
			if p1 < 0
				break
			else
				let main = strpart(prefix, 0, p1 + 1)
				let prefix = strpart(prefix, p1 + 1)
				let cc = navigator#charname#get_key_label(main)
				let cc = (cc == 'BADKEY')? main : cc
				call add(part, cc)
			endif
		else
			let cc = navigator#charname#get_key_label(ch)
			let cc = (cc == 'BADKEY')? ch : cc
			call add(part, cc)
			let prefix = strpart(prefix, 1)
		endif
	endwhile
	return join(part, ' ')
endfunc



