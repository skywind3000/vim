" EnhancedDiff.vim - Enhanced Diff functions for Vim
" -------------------------------------------------------------
" Version: 0.3
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Thu, 05 Mar 2015 08:11:46 +0100
" Script: http://www.vim.org/scripts/script.php?script_id=5121
" Copyright:   (c) 2009-2015 by Christian Brabandt
"          The VIM LICENSE applies to EnhancedDifff.vim
"          (see |copyright|) except use "EnhancedDiff.vim"
"          instead of "Vim".
"          No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 5121 3 :AutoInstall: EnhancedDiff.vim
"
" Init: {{{1
let s:cpo= &cpo
if exists("g:loaded_enhanced_diff") || &cp
    finish
endif
set cpo&vim
let g:loaded_enhanced_diff = 1

" Functions {{{1
function! s:OldGitVersion() "{{{2
    if !exists('g:enhanced_diff_old_git')
        silent let git_version = matchlist(system("git --version"),'\vgit version (\d+)\.(\d+)\.(\d+)')
        let major = git_version[1]
        let middle = git_version[2]
        let minor = git_version[3]
        let g:enhanced_diff_old_git = (major < 1) || (major == 1 && (middle < 8 || (middle == 8 && minor < 2)))
    endif
    return g:enhanced_diff_old_git
endfu
function! s:CustomDiffAlgComplete(A,L,P) "{{{2
    if s:OldGitVersion()
        return "myers\ndefault\npatience"
    else
        return "myers\nminimal\ndefault\npatience\nhistogram"
    endif
endfu
function! s:CustomIgnorePat(bang, ...) "{{{2
    if a:bang
        if a:bang && a:0  && a:1 == '-buffer'
            let b:enhanced_diff_ignore_pat=[]
        else
            let g:enhanced_diff_ignore_pat=[]
        endif
    endif
    if !exists("g:enhanced_diff_ignore_pat")
        let g:enhanced_diff_ignore_pat=[]
    endif

    if a:0
        let local = 0
        let replace = 'XXX'
        if a:0 == 3 && a:1 == '-buffer'
            let local=1
            if !exists("b:enhanced_diff_ignore_pat"))
                let b:enhanced_diff_ignore_pat=[]
            endif
        endif
        let pat = local ? a:2 : a:1
        if a:0 == 2
            let replace = local ? a:3 : a:2
        endif
        if local
            call add(b:enhanced_diff_ignore_pat, [pat, replace])
        else
            call add(g:enhanced_diff_ignore_pat, [pat, replace])
        endif
    endif
endfu
function s:EnhancedDiffExpr(algo)
    return printf('EnhancedDiff#Diff("git diff","%s")',
                \ s:OldGitVersion()
                \ ? (a:algo == "patience" ? "--patience":"")
                \ : "--diff-algorithm=".a:algo)
endfu
" public interface {{{1
com! -nargs=1 -complete=custom,s:CustomDiffAlgComplete EnhancedDiff :let &diffexpr=s:EnhancedDiffExpr("<args>")|:diffupdate
com! PatienceDiff :EnhancedDiff patience
com! EnhancedDiffDisable  :set diffexpr=
"com! -nargs=1 -bang EnhancedDiffIgnorePat if <q-bang> | :let g:enhanced_diff_ignore_pat = [<q-args>] | else | :let g:enhanced_diff_ignore_pat=get(g:, 'enhanced_diff_ignore_pat', []) + [<q-args>] |endif
com! -nargs=* -bang EnhancedDiffIgnorePat call s:CustomIgnorePat(<bang>0, <f-args>)

" Restore: "{{{1
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 sw=4 et fdm=marker com+=l\:\"
