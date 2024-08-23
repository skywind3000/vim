" Vim syntax file
" Language:               Configuration File (ini file) for MSDOS/MS Windows
" Version:                2.3
" Original Author:        Sean M. McKee <mckee@misslink.net>
" Previous Maintainer:    Nima Talebi <nima@it.net.au>
" Current Maintainer:     Hong Xu <hong@topbug.net>
" Homepage:               http://www.vim.org/scripts/script.php?script_id=3747
" Repository:             https://github.com/xuhdev/syntax-dosini.vim
" Last Change:            2023 Aug 20


" quit when a syntax file was already loaded
if exists("b:current_syntax")
  finish
endif

" using of line-continuation requires cpo&vim
let s:cpo_save = &cpo
set cpo&vim

" shut case off
syn case ignore

syn match  taskiniLabel    "^.\{-}\ze\s*=" nextgroup=taskiniNumber,taskiniValue
syn match  taskiniValue    "=\zs.*"
syn match  taskiniNumber   "=\zs\s*\d\+\s*$"
syn match  taskiniNumber   "=\zs\s*\d*\.\d\+\s*$"
syn match  taskiniNumber   "=\zs\s*\d\+e[+-]\=\d\+\s*$"
syn region taskiniHeader   start="^\s*\[" end="\]"
syn match  taskiniComment  "^[#;].*$"
syn region taskiniSection  start="\s*\[.*\]" end="\ze\s*\[.*\]" fold
      \ contains=taskiniLabel,taskiniValue,taskiniNumber,taskiniHeader,taskiniComment

" Define the default highlighting.
" Only when an item doesn't have highlighting yet

hi def link taskiniNumber   Number
hi def link taskiniHeader   Special
hi def link taskiniComment  Comment
hi def link taskiniLabel    Type
hi def link taskiniValue    String


let b:current_syntax = "taskini"

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sts=2 sw=2 et
