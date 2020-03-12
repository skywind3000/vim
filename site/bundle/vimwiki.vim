
let g:vimwiki_path = get(g:, 'vimwiki_path', '~/.vim/wiki')

let g:vimwiki_list = [{'path': g:vimwiki_path, 'ext': '.wiki'}]
" let g:vimwiki_list = [{'path': g:vimwiki_path, 'syntax':'markdown', 'ext': '.md'}]


nmap <space>ww <Plug>VimwikiIndex
nmap <space>wt <Plug>VimwikiTabIndex
nmap <space>ws <Plug>VimwikiUISelect
nmap <space>wi <Plug>VimwikiDiaryIndex

nmap <space>w<space>w <Plug>VimwikiMakeDiaryNote
nmap <space>w<space>t <Plug>VimwikiTabMakeDiaryNote
nmap <space>w<space>y <Plug>VimwikiMakeYesterdayDiaryNote
nmap <space>w<space>m <Plug>VimwikiMakeTomorrowDiaryNote



