" vim: set ts=4 sw=4 tw=78 noet :
"======================================================================
"
" utils.vim - 
"
" Created by skywind on 2022/09/04
" Last Modified: 2022/09/04 22:46
"
"======================================================================
let s:windows = asclib#common#windows
let g:asclib = get(g:, 'asclib', {})


"----------------------------------------------------------------------
" write log
"----------------------------------------------------------------------
function! asclib#utils#log(text, ...) abort
	let text = a:text . ' '. join(a:000, ' ')
	let time = strftime('%Y-%m-%d %H:%M:%S')
	let name = 'm'. strpart(time, 0, 10) . '.log'
	let name = substitute(name, '-', '', 'g')
	let home = expand('~/.vim/logs')
	let text = '['.time.'] ' . text
	let name = home .'/'. name
	if !exists('*writefile')
		return 0
	endif
	if !isdirectory(home)
		silent! call mkdir(home, 'p')
	endif
	silent! call writefile([text . "\n"], name, 'a')
	return 1
endfunc


"----------------------------------------------------------------------
" returns nearest parent directory contains one of the markers
"----------------------------------------------------------------------
function! asclib#utils#search_parent(name, markers, strict)
	let name = fnamemodify((a:name != '')? a:name : bufname('%'), ':p')
	let finding = ''
	" iterate all markers
	for marker in a:markers
		if marker != ''
			" search as a file
			let x = findfile(marker, name . '/;')
			let x = (x == '')? '' : fnamemodify(x, ':p:h')
			" search as a directory
			let y = finddir(marker, name . '/;')
			let y = (y == '')? '' : fnamemodify(y, ':p:h:h')
			" which one is the nearest directory ?
			let z = (strchars(x) > strchars(y))? x : y
			" keep the nearest one in finding
			let finding = (strchars(z) > strchars(finding))? z : finding
		endif
	endfor
	if finding == ''
		let path = (a:strict == 0)? fnamemodify(name, ':h') : ''
	else
		let path = fnamemodify(finding, ':p')
	endif
	if has('win32') || has('win16') || has('win64') || has('win95')
		let path = substitute(path, '\/', '\', 'g')
	endif
	if path =~ '[\/\\]$'
		let path = fnamemodify(path, ':h')
	endif
	return path
endfunc


"----------------------------------------------------------------------
" switch file
"----------------------------------------------------------------------
function! asclib#utils#file_switch(args)
	let filename = ''
	let opts = {}
	let cmds = []
	if type(a:args) == type('')
		let args = [a:args]
	else
		let args = a:args
	endif
	for p in args
		let p = asclib#string#strip(p)
		if strpart(p, 0, 1) == '-'
			let text = strpart(p, 1)
			let [opt, sep, val] = asclib#string#partition(text, '=')
			let opt = asclib#string#strip(opt)
			let opts[opt] = asclib#string#strip(val)
		elseif strpart(p, 0, 1) == '+'
			let cmds += [strpart(p, 1)]
		else
			let filename = p
		endif
	endfor
	if filename == ''
		call asclib#core#errmsg('require file name')
		return 0
	endif
	if !empty(cmds)
		let opts.command = cmds
	endif
	call asclib#core#switch(expand(filename), opts)
endfunc


"----------------------------------------------------------------------
" returns shebang
"----------------------------------------------------------------------
function! asclib#utils#script_shebang(script)
	let script = a:script
	if !filereadable(script)
		return ''
	endif
	let textlist = readfile(script, '', 20)
	let shebang = ''
	for text in textlist
		let text = asclib#string#strip(text)
		if text =~ '^#'
			let text = asclib#string#strip(strpart(text, 1))
			if text =~ '^!'
				let shebang = asclib#string#strip(strpart(text, 1))
				break
			endif
		endif
	endfor
	return shebang
endfunc


"----------------------------------------------------------------------
" call terminal.py
"----------------------------------------------------------------------
function! asclib#utils#terminal(mode, cmd, wait, ...) abort
	let home = asclib#setting#script_home()
	let script = asclib#path#join(home, '../../lib/terminal.py')
	let script = fnamemodify(script, ':p')
	let cmd = ''
	if a:mode != ''
		let cmd .= ' --terminal='.a:mode
	endif
	if a:wait
		let cmd .= ' -w'
	endif
	if a:0 >= 1
		let cmd .= ' --cwd='.a:1
	endif
	if a:0 >= 2
		let cmd .= ' --profile='.a:2
	endif
	let cygwin = asclib#setting#get('cygwin', '')
	if cygwin != ''
		let cmd .= ' --cygwin='.shellescape(cygwin)
	endif
	if cmd != ''
		let cmd .= ' '
	endif
	let cmd = 'python '.shellescape(script). ' ' .cmd . a:cmd
	exec 'AsyncRun -mode=5 '.cmd
endfunc



"----------------------------------------------------------------------
" dash / zeal
"----------------------------------------------------------------------
function! asclib#utils#dash(language, keyword)
	let zeal = asclib#setting#get('zeal', 'zeal.exe')
	if !executable(zeal)
		call asclib#common#errmsg('cannot find executable: '.zeal)
		return
	endif
	let url = 'dash://'.a:language.':'.a:keyword
	if asclib#setting#has_windows()
		silent! exec '!start '.shellescape(zeal). ' '.shellescape(url)
	else
		call system('open '.shellescape(url).' &')
	endif
endfunc


function! asclib#utils#dash_ft(ft, keyword)
	let groups = g:asclib#dash#module.groups
	let langs = get(groups, a:ft, [])
	call asclib#utils#dash(join(langs, ','), a:keyword)
endfunc


"----------------------------------------------------------------------
" invoke shell.py
"----------------------------------------------------------------------
function! asclib#utils#shell_invoke(mode, cmd, ...)
	let home = asclib#setting#script_home()
	let script = asclib#path#join(home, '../../lib/shell.py')
	let script = fnamemodify(script, ':p')
	let cmdline = 'python ' . shellescape(script) . ' ' . a:cmd
	for i in range(a:0)
		let cmdline .= ' ' . shellescape(a:{i + 1})
	endfor
	exec 'AsyncRun -raw=1 -mode='.a:mode.' '.cmdline
endfunc


"----------------------------------------------------------------------
" shell - gdb 
"----------------------------------------------------------------------
function! asclib#utils#emacs_gdb(exename)
	if asclib#setting#has_windows()
		let emacs = asclib#setting#get('emacs', 'runemacs.exe')
		let gdb = asclib#setting#get('gdb', 'gdb.exe')
		call asclib#utils#shell_invoke(5, '-E', emacs, gdb, a:exename)
	else
		let emacs = asclib#setting#get('emacs', 'emacs')
		let gdb = asclib#setting#get('gdb', 'gdb')
		call asclib#utils#shell_invoke(2, '-E', emacs, gdb, a:exename)
	endif
endfunc


"----------------------------------------------------------------------
" search gtags config
"----------------------------------------------------------------------
function! asclib#utils#gtags_search_conf()
	let rc = get(g:, 'gutentags_plus_rc', '')
	if rc != ''
		if filereadable(rc)
			return asclib#path#abspath(rc)
		endif
	endif
	let rc = asclib#path#abspath(expand('~/.globalrc'))
	if filereadable(rc)
		return rc
	endif
	let rc = asclib#path#abspath(expand('~/.gtags'))
	if filereadable(rc)
		return rc
	endif
	if g:asclib#common#unix != 0
		let rc = '/etc/gtags.conf'
		if filereadable(rc)
			return rc
		endif
		let rc = '/usr/local/etc/gtags.conf'
		if filereadable(rc)
			return rc
		endif
	endif
	let gtags = get(g:, 'gutentags_gtags_executable', 'gtags')
	let gtags = asclib#path#executable(gtags)
	if gtags == ''
		return ''
	endif
	let ghome = asclib#path#dirname(gtags)
	let rc = asclib#path#join(ghome, '../share/gtags/gtags.conf')
	let rc = asclib#path#abspath(rc)
	if filereadable(rc)
		return rc
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" init gtags
"----------------------------------------------------------------------
function! asclib#utils#gtags_environment()
	let conf = asclib#utils#gtags_search_conf()
	if conf != ''
		let $GTAGSCONF = conf
		let $GTAGSLABEL = 'native-pygments'
		let $GTAGSFORCECPP = '1'
	endif
endfunc


"----------------------------------------------------------------------
" get gui colors
"----------------------------------------------------------------------
function! s:match_highlight(highlight, pattern) abort
	let matches = matchlist(a:highlight, a:pattern)
	if len(matches) == 0
		return 'NONE'
	endif
	return matches[1]
endfunc

function! asclib#utils#get_bg_colors(group) abort
	redir => highlight
	silent execute 'silent highlight ' . a:group
	redir END
	let link_matches = matchlist(highlight, 'links to \(\S\+\)')
	if len(link_matches) > 0 " follow the link
		return s:get_background_colors(link_matches[1])
	endif
	let ctermbg = s:match_highlight(highlight, 'ctermbg=\([0-9A-Za-z]\+\)')
	let guibg   = s:match_highlight(highlight, 'guibg=\([#0-9A-Za-z]\+\)')
	return [guibg, ctermbg]
endfunc


"----------------------------------------------------------------------
" open url in browser
"----------------------------------------------------------------------
function! asclib#utils#open_url(url, ...)
	let url = escape(a:url, "%|*#")
	let bang = (a:0 > 0)? (a:1) : ''
	let browser = asclib#setting#get('browser', '')
	let browser = (bang == '!')? '' : browser
	if has('win32') || has('win64') || has('win16') || has('win95')
		if browser == ''
			silent exec '!start /b cmd /c start ' . url . ''
		else
			silent exec '!start /b cmd /c call ' . browser . ' "' . a:url . '"'
		endif
		unsilent echo browser
	elseif has('mac') || has('macunix') || has('gui_macvim')
		let browser = (browser == '')? 'open' : browser
		call system(browser . " " . url . " &")
	else
		let cmd = '/mnt/c/Windows/System32/cmd.exe'
		if $WSL_DISTRO_NAME != '' && executable(cmd)
			if executable('xdg-open') == 0 || browser =~ '\\'
				if $WSL_DISTRO_NAME != ''
					let browser = (browser == '')? 'start' : browser
					call system(cmd . ' /C ' . browser . ' ' . url . ' &')
					return
				endif
			endif
		endif
		let browser = (browser == '')? 'xdg-open' : browser
		call system(browser . ' ' . url . ' &')
	endif
endfunc


"----------------------------------------------------------------------
" browse code in github gitlab
"----------------------------------------------------------------------
function! asclib#utils#git_browse(name, ...)
	let name = (a:name == '')? expand('%:p') : (a:name)
	let root = asclib#vcs#root(name)
	if root == ''
		return ''
	endif
	let remote = asclib#git#get_remote(root, 'origin')
	if remote == ''
		return ''
	endif
	let branch = asclib#git#get_branch(root)
	if branch == ''
		return ''
	endif
	let uri = asclib#vcs#relpath(name)
	if uri == ''
		return ''
	endif
	let raw = (a:0 > 0)? (a:1) : 0
	if remote =~ '^https:\/\/github\.com\/'
		let text = matchstr(remote, '^https:\/\/github\.com\/\zs.*$')
		if text =~ '\.git$'
			let text = matchstr(text, '.*\ze\.git$')
		endif
		let url = 'https://github.com/' . text 
		if raw == 0
			return url . '/blob/' . branch . '/' . uri
		else
			return url . '/raw/' . branch . '/' . uri
		endif
	elseif remote =~ '^git@github\.com:'
		let text = matchstr(remote, '^git@github\.com:\zs.*$')
		if text =~ '\.git$'
			let text = matchstr(text, '.*\ze\.git$')
		endif
		let url = 'https://github.com/' . text 
		if raw == 0
			return url . '/blob/' . branch . '/' . uri
		else
			return url . '/raw/' . branch . '/' . uri
		endif
	elseif remote =~ '^https:\/\/gitlab\.com\/'
		let text = matchstr(remote, '^https:\/\/gitlab\.com\/\zs.*$')
		if text =~ '\.git$'
			let text = matchstr(text, '.*\ze\.git$')
		endif
		let url = 'https://gitlab.com/' . text 
		if raw == 0
			return url . '/-/blob/' . branch . '/' . uri
		else
			return url . '/-/raw/' . branch . '/' . uri
		endif
	elseif remote =~ '^git@gitlab\.com:'
		let text = matchstr(remote, '^git@gitlab\.com:\zs.*$')
		if text =~ '\.git$'
			let text = matchstr(text, '.*\ze\.git$')
		endif
		let url = 'https://gitlab.com/' . text 
		if raw == 0
			return url . '/-/blob/' . branch . '/' . uri
		else
			return url . '/-/raw/' . branch . '/' . uri
		endif
	elseif remote =~ '^https\?:\/\/gitlab.alibaba-inc.com\/'
		let t = matchstr(remote, '^https\?:\/\/gitlab.alibaba-inc.com\/\zs.*$')
		if t =~ '\.git$'
			let t = matchstr(t, '.*\ze\.git$')
		endif
		let url = 'https://code.alibaba-inc.com/' . t . '/blob/'
		return url . branch . '/' . uri
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" display help
"----------------------------------------------------------------------
function! asclib#utils#display(name, mods) abort
	if type(a:name) == type('')
		if !filereadable(a:name)
			call asclib#common#errmsg("E484: Can't open file " .. a:name)
			return -1
		endif
	endif
	if a:mods == 'tab'
		exec 'tab split'
	elseif asclib#buffer#getvar(0, '_for_display', 0) == 0
		let avail = -1
		for i in range(winnr('$'))
			let bid = winbufnr(i + 1)
			if asclib#buffer#getvar(bid, '_for_display', 0) != 0
				let avail = i + 1
				break
			endif
		endfor
		if avail > 0
			exec avail . 'wincmd w'
		elseif a:mods == 'auto'
			if winwidth(0) >= 160
				exec 'vsplit'
			else
				exec 'split'
			endif
		else
			exec a:mods . ' split'
		endif
	endif
	if type(a:name) == type(0)
		exec printf('buffer %d', a:name)
	else 
		exec 'edit ' . fnameescape(a:name)
	endif
	call asclib#buffer#setvar(0, '_for_display', 1)
	return 0
endfunc


"----------------------------------------------------------------------
" make current buffer infomation buffer
"----------------------------------------------------------------------
function! asclib#utils#make_info_buf() abort
	setl bt=help nomodifiable nobuflisted noswapfile readonly 
	setl nonumber norelativenumber signcolumn=no
	setl fdc=0 nofen nocursorline nocursorcolumn 
endfunc


"----------------------------------------------------------------------
" current url
"----------------------------------------------------------------------
function! asclib#utils#current_url() abort
	let github = 'https://github.com/'
	let text = expand('<cfile>')
	if text =~ '^\(http\|https\):\/\/'
		return text
	endif
	let text = getline('.')
	let t = matchstr(text, '^\s*Plug\s*''\zs\(.\{-}\)*\ze''')
	if t != ''
		return (t =~ '^\(http\|https\):\/\/')? t : (github . t)
	endif
	let t = matchstr(text, '^\s*Plugin\s*''\zs\(.\{-}\)*\ze''')
	if t != ''
		return (t =~ '^\(http\|https\):\/\/')? t : (github . t)
	endif
	let t = matchstr(text, '^\s*''\zs\(.\{-}\)*\ze''')
	if t != ''
		if stridx(t, '/') > 0
			return (t =~ '^\(http\|https\):\/\/')? t : (github . t)
		endif
	endif
	let t = matchstr(text, '^\s*{\s*''\zs\(.\{-}\)*\ze''')
	if t != ''
		if stridx(t, '/') > 0
			return (t =~ '^\(http\|https\):\/\/')? t : (github . t)
		endif
	endif
	let t = matchstr(text, '^\s*"\zs\(.\{-}\)*\ze"')
	if t != ''
		if stridx(t, '/') > 0
			return (t =~ '^\(http\|https\):\/\/')? t : (github . t)
		endif
	endif
	let t = matchstr(text, '^\s*{\s*"\zs\(.\{-}\)*\ze"')
	if t != ''
		if stridx(t, '/') > 0
			return (t =~ '^\(http\|https\):\/\/')? t : (github . t)
		endif
	endif
	let text = expand('<cfile>')
	if text =~ '^\w\+\/\w\+'
		return github . text
	endif
	return ''
endfunc



"----------------------------------------------------------------------
" remove path from $PATH
"----------------------------------------------------------------------
function! asclib#utils#path_remove(what) abort
	let sep = (s:windows != 0)? ';' : ','
	let paths = []
	for path in split($PATH, sep)
		if !asclib#path#equal(path, a:what)
			call add(paths, path)
		endif
	endfor
	let $PATH = join(paths, sep)
endfunc


