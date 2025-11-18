"======================================================================
"
" fugitive.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 12:24:53
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win64') || has('win95')
let s:quickfix = {}


"----------------------------------------------------------------------
" fugitive:///home/user/.vim/vim/.git//HASH
" fugitive:///home/user/.vim/vim/.git//HASH/autoload/gdv/git.vim
" fugitive:///home/user/.vim/vim/.git/module/NAME//HASH
" fugitive:///home/user/.vim/vim/.git/module/NAME//HASH/path/file
"----------------------------------------------------------------------
function! gdv#fugitive#translate(name) abort
	let name = a:name
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let path = substitute(name, '^fugitive:[\\/][\\/]', '', '')
	if s:windows && path =~ '^[\\/]\a\:'
		let path = strpart(path, 1)
	endif
	let path = substitute(path, '[\\/][\\/].*$', '', '')
	return gdv#git#git2root(path)
endfunc


"----------------------------------------------------------------------
" get git root for fugitive buffer
"----------------------------------------------------------------------
function! gdv#fugitive#root(bid) abort
	let name = bufname(a:bid)
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let path = getbufvar(a:bid, 'git_dir', '')
	if path != ''
		let path = gdv#git#git2root(path)
		if path != ''
			return path
		endif
	endif
	let path = gdv#fugitive#translate(name)
	if path != ''
		if isdirectory(path)
			return path
		endif
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get fugitive quickfix entry buffer id
"----------------------------------------------------------------------
function! gdv#fugitive#qf_entry(index) abort
	let items = getqflist({'title':1, 'id':0})
	let title = quickui#core#string_strip(items.title)
	if title !~ ':Gclog'
		return -1
	endif
	if !has_key(s:quickfix, items.id)
		let s:quickfix[items.id] = getqflist()
	endif
	let content = s:quickfix[items.id]
	let index = a:index
	if index < 0 || index >= len(content)
		return -1
	endif
	let item = content[index]
	if !item.valid
		return -1
	endif
	let bid = item.bufnr
	if strlen(item.module) < 4
		return -1
	endif
	return bid
endfunc


"----------------------------------------------------------------------
" get git root from quickfix list item (works even if buffer is not open)
"----------------------------------------------------------------------
function! gdv#fugitive#qf_root(index) abort
	let items = getqflist({'title':1, 'id':0})
	if !has_key(s:quickfix, items.id)
		let s:quickfix[items.id] = getqflist()
	endif
	let content = s:quickfix[items.id]
	if a:index < 0 || a:index >= len(content)
		return ''
	endif
	let item = content[a:index]
	if item.bufnr > 0
		let bufname_str = ''
		if exists('*getbufinfo')
			try
				let buf_info = getbufinfo(item.bufnr)
				if len(buf_info) > 0 && has_key(buf_info[0], 'name')
					let bufname_str = buf_info[0].name
				endif
			catch
			endtry
		endif
		if bufname_str == ''
			let bufname_str = bufname(item.bufnr)
		endif
		if bufname_str != '' && bufname_str =~ '^fugitive:[\\/][\\/]'
			let root = gdv#fugitive#root(item.bufnr)
			if root != ''
				return root
			endif
		endif
	endif
	" Try to extract root from quickfix title
	" For :Gclog, title might contain the git directory path
	let title = items.title
	if title != ''
		" Title format might be: "git -C <path> log ..." or similar
		" Try to extract path from title
		let path = matchstr(title, '-C\s\+\zs[^\s]\+')
		if path != ''
			let root = gdv#git#root(path)
			if root != ''
				return root
			endif
		endif
	endif
	" Fallback: try to find root from current context
	let root = gdv#git#root('')
	if root != ''
		return root
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" fugitive quickfix commit extractor 
"----------------------------------------------------------------------
function! gdv#fugitive#qf_commit() abort
	if &bt != 'quickfix'
		return ''
	endif
	" Get quickfix list item for current line
	let items = getqflist({'title':1, 'id':0})
	if !has_key(s:quickfix, items.id)
		let s:quickfix[items.id] = getqflist()
	endif
	let content = s:quickfix[items.id]
	let index = line('.') - 1
	if index < 0 || index >= len(content)
		return ''
	endif
	let item = content[index]
	if has_key(item, 'module') && strlen(item.module) >= 4
		let bid = gdv#fugitive#qf_entry(index)
		if bid >= 0
			let hash = gdv#fugitive#commit_hash(bid)
			if hash != ''
				return hash
			endif
		endif
		let root = gdv#fugitive#qf_root(index)
		if root != ''
			let full_hash = gdv#git#commit_hash(root, item.module)
			if full_hash != ''
				return full_hash
			endif
		endif
		" Fallback: use short hash directly
		return item.module
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get git root for nofile buffer
"----------------------------------------------------------------------
function! gdv#fugitive#nofile_root() abort
	if &bt == ''
		return ''
	elseif &bt == 'nofile'
		if &ft == 'floggraph'
			if exists('b:flog_state')
				return get(b:flog_state, 'workdir', '')
			endif
		elseif &ft == 'agit_stat' || &ft == 'agit_diff'
			if exists('t:git')
				if has_key(t:git, 'git_root')
					return t:git['git_root']
				endif
			endif
		elseif &ft == 'magit'
			if exists('b:magit_top_dir')
				return b:magit_top_dir
			endif
		elseif &ft == 'NeogitStatus' && has('nvim')
			try
				let t = luaeval('require("neogit.lib.git").repo.git_root')
				return t
			catch
			endtry
		endif
		if exists('b:git_dir') && get(b:, 'git_dir', '') != ''
			let git_dir = b:git_dir
			" For submodules, b:git_dir might point to the actual gitdir
			" (e.g., parent/.git/modules/submodule), not the work tree
			" Check if git_dir is a gitdir (contains .git/modules/)
			if git_dir =~ '[\\/]\.git[\\/]modules[\\/]'
				" This is a gitdir, extract parent path and submodule relative path
				" Path format: d:/WeirdData/vim-init/.git/modules/pack/mydev/opt/vim-git-diffview
				" Parent: d:/WeirdData/vim-init
				" Submodule path: pack/mydev/opt/vim-git-diffview
				let parent_path = substitute(git_dir, '[\\/]\.git[\\/]modules.*$', '', '')
				let submodule_rel_path = matchstr(git_dir, '[\\/]\.git[\\/]modules[\\/]\zs.*$')
				if parent_path != '' && submodule_rel_path != '' && parent_path != git_dir
					let work_tree = parent_path . '/' . submodule_rel_path
					" Normalize path separators
					if s:windows
						let work_tree = substitute(work_tree, '/', '\', 'g')
					endif
					if isdirectory(work_tree)
						" Verify this is the work tree (has .git file pointing to gitdir)
						let git_file = work_tree . '/.git'
						if filereadable(git_file)
							let root = gdv#git#root(work_tree)
							if root != ''
								if s:windows
									let root = quickui#core#string_replace(root, '/', '\')
								endif
								return root
							endif
						endif
					endif
				endif
			elseif isdirectory(git_dir) && filereadable(git_dir . '/config')
				" This is a gitdir, try to get work tree using git command
				" But we need to find the work tree first
				" Try to get work tree from a file in the gitdir
				try
					" Use git command to get work tree, but we need to run it in the work tree
					" First, try to find work tree by going up from git_dir
					let test_path = git_dir
					while test_path != '' && test_path != fnamemodify(test_path, ':h')
						let test_path = fnamemodify(test_path, ':h')
						let git_file = test_path . '/.git'
						if filereadable(git_file)
							" Check if this .git file points to our git_dir
							try
								let lines = readfile(git_file)
								if len(lines) > 0
									let gitdir_line = quickui#core#string_strip(lines[0])
									if gitdir_line =~ '^gitdir:\s*'
										let gitdir_path = matchstr(gitdir_line, '^gitdir:\s*\zs.*$')
										let gitdir_path = quickui#core#string_strip(gitdir_path)
										if gitdir_path !~ '^[\\/]\|^\a:'
											let gitdir_path = fnamemodify(test_path . '/' . gitdir_path, ':p')
											let gitdir_path = substitute(gitdir_path, '[\\/]$', '', '')
										endif
										if s:windows
											let gitdir_path = substitute(gitdir_path, '/', '\', 'g')
										endif
										if gitdir_path == git_dir || simplify(gitdir_path) == simplify(git_dir)
											" Found the work tree
											let root = gdv#git#root(test_path)
											if root != ''
												if s:windows
													let root = quickui#core#string_replace(root, '/', '\')
												endif
												return root
											endif
										endif
									endif
								endif
							catch
							endtry
						endif
					endwhile
				catch
				endtry
			endif
			" Fallback: assume git_dir is the .git directory, get parent
			let r = git_dir
			if r =~ '[\\/]\.git$'
				let r = substitute(r, '[\\/]\.git$', '', '')
			endif
			" Verify this is a valid git repository
			if r != '' && isdirectory(r)
				let git_path = r . '/.git'
				if isdirectory(git_path) || filereadable(git_path)
					return r
				endif
			endif
		endif
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get current git root from variaous fugitive contexts
"----------------------------------------------------------------------
function! gdv#fugitive#current_root() abort
	if &bt == 'nofile'
		let root = gdv#fugitive#nofile_root()
		if root != '' && isdirectory(root)
			" Verify this is a valid git repository
			let git_path = root . '/.git'
			if isdirectory(git_path) || filereadable(git_path)
				return root
			endif
		endif
		" Fallback: try to find git root from current context
		" This handles submodules where nofile_root() might fail
		let root = gdv#git#root('')
		if root != ''
			return root
		endif
	elseif &bt == 'quickfix'
		" Try to get root from quickfix list item first (works even if buffer not open)
		let root = gdv#fugitive#qf_root(line('.') - 1)
		if root != ''
			return root
		endif
		" Fallback: try buffer-based method
		let bid = gdv#fugitive#qf_entry(line('.') - 1)
		if bid >= 0
			let root = gdv#fugitive#root(bid)
			if root != '' && isdirectory(root)
				return root
			endif
		endif
		" Final fallback: try to find git root from current context
		" This handles submodules where gdv#fugitive#root() might fail
		" because it assumes .git is a directory, not a file
		let root = gdv#git#root('')
		if root != ''
			return root
		endif
	elseif &bt == 'nowrite' && &ft == 'git'
		" For git log output windows, try to find git root from current context
		" This handles both normal repos and submodules
		let root = gdv#git#root('')
		if root != ''
			return root
		endif
		" Fallback: try to use b:git_dir if available
		if exists('b:git_dir')
			let git_dir = b:git_dir
			" For git submodules, b:git_dir might point to the actual gitdir
			" (e.g., parent/.git/modules/submodule), not the work tree
			" Check if git_dir is a gitdir (contains .git/modules/)
			if git_dir =~ '[\\/]\.git[\\/]modules[\\/]'
				" This is a gitdir, extract parent path and submodule relative path
				" Path format: d:/WeirdData/vim-init/.git/modules/pack/mydev/opt/vim-git-diffview
				" Parent: d:/WeirdData/vim-init
				" Submodule path: pack/mydev/opt/vim-git-diffview
				let parent_path = substitute(git_dir, '[\\/]\.git[\\/]modules.*$', '', '')
				let submodule_rel_path = matchstr(git_dir, '[\\/]\.git[\\/]modules[\\/]\zs.*$')
				if parent_path != '' && submodule_rel_path != '' && parent_path != git_dir
					let work_tree = parent_path . '/' . submodule_rel_path
					" Normalize path separators
					if s:windows
						let work_tree = substitute(work_tree, '/', '\', 'g')
					endif
					if isdirectory(work_tree)
						" Verify this is the work tree (has .git file pointing to gitdir)
						let git_file = work_tree . '/.git'
						if filereadable(git_file)
							let root = gdv#git#root(work_tree)
							if root != ''
								if s:windows
									let root = quickui#core#string_replace(root, '/', '\')
								endif
								return root
							endif
						endif
					endif
				endif
			elseif isdirectory(git_dir) && filereadable(git_dir . '/config')
				" This is a gitdir, try to get work tree using git command
				" But we need to find the work tree first
				" Try to get work tree from a file in the gitdir
				try
					" Use git command to get work tree, but we need to run it in the work tree
					" First, try to find work tree by going up from git_dir
					let test_path = git_dir
					while test_path != '' && test_path != fnamemodify(test_path, ':h')
						let test_path = fnamemodify(test_path, ':h')
						let git_file = test_path . '/.git'
						if filereadable(git_file)
							" Check if this .git file points to our git_dir
							try
								let lines = readfile(git_file)
								if len(lines) > 0
									let gitdir_line = quickui#core#string_strip(lines[0])
									if gitdir_line =~ '^gitdir:\s*'
										let gitdir_path = matchstr(gitdir_line, '^gitdir:\s*\zs.*$')
										let gitdir_path = quickui#core#string_strip(gitdir_path)
										if gitdir_path !~ '^[\\/]\|^\a:'
											let gitdir_path = fnamemodify(test_path . '/' . gitdir_path, ':p')
											let gitdir_path = substitute(gitdir_path, '[\\/]$', '', '')
										endif
										if s:windows
											let gitdir_path = substitute(gitdir_path, '/', '\', 'g')
										endif
										if gitdir_path == git_dir || simplify(gitdir_path) == simplify(git_dir)
											" Found the work tree
											let root = gdv#git#root(test_path)
											if root != ''
												if s:windows
													let root = quickui#core#string_replace(root, '/', '\')
												endif
												return root
											endif
										endif
									endif
								endif
							catch
							endtry
						endif
					endwhile
				catch
				endtry
			endif
			" Fallback: assume git_dir is the .git directory, get parent
			let root = git_dir
			if root =~ '[\\/]\.git$'
				let root = substitute(root, '[\\/]\.git$', '', '')
			endif
			if isdirectory(root)
				" Verify this is a valid git repository
				let git_path = root . '/.git'
				if isdirectory(git_path) || filereadable(git_path)
					return root
				endif
			endif
		endif
	endif
	let git = gdv#git#current_object()
	if has_key(git, 'root')
		return git.root
	endif
	let root = gdv#fugitive#root('%')
	if root != '' && isdirectory(root)
		" Verify this is a valid git repository
		let git_path = root . '/.git'
		if isdirectory(git_path) || filereadable(git_path)
			let git.root = root
			return root
		endif
	endif
	" Final fallback: use gdv#git#root() which handles submodules
	let root = gdv#git#root('')
	if root != '' && isdirectory(root)
		let git.root = root
		return root
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get commit hash for fugitive buffer
"----------------------------------------------------------------------
function! gdv#fugitive#commit_hash(bid)
	let name = bufname(a:bid)
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	" Extract commit hash from buffer name
	" Format: fugitive://path/.git//commit
	" For submodules: fugitive://path/.git/modules/submodule//commit
	" The commit hash is always after the last "//"
	let part = matchstr(name, '[\\/][\\/]\zs[^\\/]*$')
	if part == ''
		" Try to find commit hash after // (may have path after it)
		let part = matchstr(name, '[\\/][\\/]\zs[0-9a-f]\{4,40}\ze')
		if part != ''
			return part
		endif
		" Last resort: extract everything after //
		let part = matchstr(name, '[\\/][\\/]\zs.*$')
		if part != ''
			" Take the first part (before next /)
			let commit = substitute(part, '[\\/].*$', '', '')
			if commit =~ '^[0-9a-f]\{4,40}$'
				return commit
			endif
		endif
	else
		" part is everything after //, commit is the first segment
		let commit = substitute(part, '[\\/].*$', '', '')
		if commit =~ '^[0-9a-f]\{4,40}$'
			return commit
		endif
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" build fugitive file name
"----------------------------------------------------------------------
function! gdv#fugitive#make(root, commit, fn) abort
	let name = 'fugitive://'
	if s:windows
		let name .= '/'
	endif
	let root = a:root
	if root =~ '^\~'
		let root = expand(root)
	endif
	let name .= root . '/.git//' . a:commit
	if a:fn != ''
		let name .= '/' . a:fn
	endif
	if s:windows
		let name = quickui#core#string_replace(name, '/', "\\")
	endif
	return name
endfunc


