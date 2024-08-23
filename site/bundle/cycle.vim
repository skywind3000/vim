
"----------------------------------------------------------------------
" keymap
"----------------------------------------------------------------------
noremap <silent> <Plug>CycleFallbackNext <C-A>
noremap <silent> <Plug>CycleFallbackPrev <C-X>
nmap <silent> <c-a> <Plug>CycleNext
vmap <silent> <c-a> <Plug>CycleNext
nmap <silent> <c-x> <Plug>CyclePrev
vmap <silent> <c-x> <Plug>CyclePrev


"----------------------------------------------------------------------
" https://github.com/bootleq/vim-cycle
"----------------------------------------------------------------------
let g:cycle_default_groups = [
			\   [['true', 'false']],
			\   [['yes', 'no']],
			\   [['on', 'off']],
			\   [['+', '-']],
			\   [['>', '<']],
			\   [['"', "'"]],
			\   [['==', '!=']],
			\   [['and', 'or']],
			\   [["in", "out"]],
			\   [["up", "down"]],
			\   [["min", "max"]],
			\   [["get", "set"]],
			\   [["add", "remove"]],
			\   [["to", "from"]],
			\   [["read", "write"]],
			\   [["only", "except"]],
			\   [['without', 'with']],
			\   [["exclude", "include"]],
			\   [["asc", "desc"]],
			\   [["begin", "end"]],
			\   [["first", "last"]],
			\   [["slow", "fast"]],
			\   [["small", "large"]],
			\   [["push", "pull"]],
			\   [["before", "after"]],
			\   [["new", "delete"]],
			\   [["while", "until"]],
			\   [["up", "down"]],
			\   [["left", "right"]],
			\   [["top", "bottom"]],
			\   [["one", "two", "three", "four", "five", "six", "seven",
			\     "eight", "nine", "ten"]],
			\   [['是', '否']],
			\   [['void', 'int', 'char']],
			\   [['{:}', '[:]', '(:)'], 'sub_pairs'],
			\   [['（:）', '「:」', '『:』'], 'sub_pairs'],
			\   [['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
			\     'Friday', 'Saturday'], 'hard_case', {'name': 'Days'}],
			\   [['January', 'February', 'March', 'April', 'May', 'June', 
			\     'July', 'August', 'September', 'October', 'November', 
			\     'December'], 'hard_case', {'name': 'Months'}],
			\ ]



