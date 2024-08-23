"----------------------------------------------------------------------
" guard: take care vim-plug call setfiletype multiple times
"----------------------------------------------------------------------
if exists('b:ftplugin_init_cpp')
	finish
endif

let b:ftplugin_init_cpp = 1

setlocal commentstring=//\ %s
let b:commentary_format = "// %s"

let b:cursorword = 1


"----------------------------------------------------------------------
" navigator
"----------------------------------------------------------------------
let b:navigator = get(b:, 'navigator', {})
let b:navigator.c = get(b:navigator, 'c', {'name': '+coding'})

let b:navigator.c.c = ['module#cpp#copy_definition()', 'copy-method-definition']
let b:navigator.c.p = ['module#cpp#paste_implementation()', 'paste-implementation']
let b:navigator.c.n = ['module#cpp#create_non_copyable()', 'create-non-copyable']


