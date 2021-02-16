" Author: Lin Wei, skywind3000(at)gmail.com
" Description: splint linter for c files

if get(g:, 'ale_enabled', 0) == 0
	finish
endif

call ale#Set('c_splint_executable', 'splint')
call ale#Set('c_splint_options', '')
call ale#Set('c_splint_type', 'W')

function! s:splint_GetExecutable(buffer) abort
    return ale#Var(a:buffer, 'c_splint_executable')
endfunction


function! s:splint_GetCommand(buffer) abort
    " Search upwards from the file for .splintrc
    "
    " If we find it, we'll `cd` to where the .splintrc file is,
    " then use the file to set up import paths, etc.
    let l:splintrc_path = ale#path#FindNearestFile(a:buffer, '.splintrc')

    let l:cd_command = !empty(l:splintrc_path)
    \   ? ale#path#CdString(fnamemodify(l:splintrc_path, ':h'))
    \   : ''
    let l:splintrc_option = !empty(l:splintrc_path)
    \   ? '-f .splintrc '
    \   : ''

    return l:cd_command
    \   . ale#Escape(s:splint_GetExecutable(a:buffer))
    \   . ' -showfunc -hints +quiet -parenfileformat -linelen 999 '
    \   . l:splintrc_option
    \   . ale#Var(a:buffer, 'c_splint_options')
    \   . ' ' . ale#Escape(fnamemodify(bufname(a:buffer), ':p')) . ' '
endfunction

function! s:splint_Handler(buffer, lines) abort
    let l:pattern = '\v^([a-zA-Z]?:?[^:]+):(\d+):?(\d+)?:? ?(.+)$'
    let l:output = []
    let l:dir = expand('#' . a:buffer . ':p:h')
    let l:msg_type = ale#Var(a:buffer, 'c_splint_type')

    for l:match in ale#util#GetMatches(a:lines, l:pattern)
        call add(l:output, {
        \   'filename': ale#path#GetAbsPath(l:dir, l:match[1]),
        \   'lnum': l:match[2] + 0,
        \   'col': l:match[3] + 0,
        \   'text': l:match[4],
        \   'type': l:msg_type,
        \})
    endfor
    return l:output
endfunction

call ale#linter#Define('c', {
\   'name': 'splint',
\   'output_stream': 'both',
\   'executable': function('s:splint_GetExecutable'),
\   'command': function('s:splint_GetCommand'),
\   'callback': function('s:splint_Handler'),
\})



