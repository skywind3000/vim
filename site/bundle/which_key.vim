
let g:which_key_use_floating_win = 1
let g:which_key_disable_default_offset = 1

hi! default link WhichKeyFloating QuickDefaultPreview


silent! call which_key#register('TAB', "g:which_key_map")
nnoremap <silent> <TAB><TAB> :<C-u>WhichKey 'TAB'<CR>
vnoremap <silent> <TAB><TAB> :<C-u>WhichKeyVisual 'TAB'<CR>

let g:which_key_map = get(g:, 'which_key_map', {})

let g:which_key_map.c = {
  \ 'name': '+comments',
  \ 'c': 'comment-lines',
  \ 'n': 'comment-lines-force-nesting',
  \ ' ': 'toggle-comment',
  \ 'm': 'comment-lines-with-block-comment',
  \ 'i': 'toggle-individual-line-comment',
  \ 's': 'comment-lines-documentation-style',
  \ 'y': 'yank-and-comment-lines',
  \ '$': 'comment-to-the-end',
  \ 'A': 'add-comment-to-end-of-line',
  \ 'a': 'switch-comment-delimiters',
  \ 'l': 'comment-left-aligned',
  \ 'b': 'comment-both-side-aligned',
  \ 'u': 'uncomment-lines'
  \ }

let g:which_key_map.s = {
  \ 'name': '+search-replace',
  \ 'r': 'search-replace-to-the-end',
  \ 'g': 'search-replace-whole-file',
  \ 'R': 'search-replace-to-the-end-no-prompt',
  \ 'G': 'search-replace-whole-file-no-prompt'
  \ }


let g:which_key_map.w = {
  \ 'name': '+window',
  \ 'p': ['<C-w>p', 'jump-previous-window'],
  \ 'h': ['<C-w>h', 'jump-left-window'],
  \ 'j': ['<C-w>j', 'jump-belowing-window'],
  \ 'k': ['<C-w>k', 'jump-aboving-window'],
  \ 'l': ['<C-w>l', 'jump-right-window'],
  \ 'H': ['<C-w>H', 'move-window-to-left'],
  \ 'J': ['<C-w>J', 'move-window-to-bottom'],
  \ 'K': ['<C-w>K', 'move-window-to-top'],
  \ 'L': ['<C-w>L', 'move-window-to-right'],
  \ 'n': ['<C-w>n', 'new-window'],
  \ 'q': ['<C-w>q', 'close-window'],
  \ 'w': ['<C-w>w', 'jump-next-window'],
  \ 'o': ['<C-w>o', 'close-all-other-windows'],
  \ 'v': ['<C-w>v', 'vertically-split-window'],
  \ 's': ['<C-w>s', 'split-window'],
  \ '/': [':Leaderf window', 'search-for-a-window'],
  \ }

