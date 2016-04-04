
command! -bang -nargs=* Es call escope#command('<bang>', <f-args>)


noremap <space>cb :Es! build cscope %<cr>
noremap <space>cs :Es! find cscope s <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>cg :Es! find cscope g <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>cc :Es! find cscope c <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>ct :Es! find cscope t <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>ce :Es! find cscope e <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>cd :Es! find cscope d <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>ca :Es! find cscope a <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>cf :Es! find cscope f <C-R>=expand("<cfile>")<CR> %<CR>
noremap <space>ci :Es! find cscope i <C-R>=expand("<cfile>")<CR> %<CR>

noremap <space>qb :Es! build gtags %<cr>
noremap <space>qu :Es! update gtags %<cr>
noremap <space>qs :Es! find gtags s <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qg :Es! find gtags g <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qc :Es! find gtags c <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qt :Es! find gtags t <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qe :Es! find gtags e <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qd :Es! find gtags d <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qa :Es! find gtags a <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>qf :Es! find gtags f <C-R>=expand("<cfile>")<CR> %<CR>
noremap <space>qi :Es! find gtags i <C-R>=expand("<cfile>")<CR> %<CR>

noremap <space>wb :Es! build pycscope %<cr>
noremap <space>ws :Es! find pycscope s <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>wg :Es! find pycscope g <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>wc :Es! find pycscope c <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>wt :Es! find pycscope t <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>we :Es! find pycscope e <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>wd :Es! find pycscope d <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>wa :Es! find pycscope a <C-R>=expand("<cword>")<CR> %<CR>
noremap <space>wf :Es! find pycscope f <C-R>=expand("<cfile>")<CR> %<CR>
noremap <space>wi :Es! find pycscope i <C-R>=expand("<cfile>")<CR> %<CR>




