" Author: Bart Libert <bart.libert@gmail.com>
" Description: cppcheck linter for c files

if get(g:, 'ale_enabled', 0) == 0
	finish
endif

call ale#Set('c_cppcheck_executable', 'cppcheck')
call ale#Set('c_cppcheck_options', '--enable=style')

call ale#Set('cpp_cppcheck_executable', 'cppcheck')
call ale#Set('cpp_cppcheck_options', '--enable=style')

function! s:c_cppcheck_GetCommand(buffer) abort
    let l:cd_command = ale#handlers#cppcheck#GetCdCommand(a:buffer)
    let l:compile_commands_option = ale#handlers#cppcheck#GetCompileCommandsOptions(a:buffer)
    let l:buffer_path_include = empty(l:compile_commands_option)
    \   ? ale#handlers#cppcheck#GetBufferPathIncludeOptions(a:buffer)
    \   : ''

    if has('win32') || has('win16') || has('win95') || has('win64')
        let l:template = ' --template=^"{file}:{line}:{column}: {severity}:{inconclusive:inconclusive:} {message} [{id}]\\n{code}^"'
    else
        let l:template = ' --template=''{file}:{line}:{column}: {severity}:{inconclusive:inconclusive:} {message} [{id}]\\n{code}'''
    endif

    return l:cd_command
    \   . '%e -q --language=c'
    \   . l:template
    \   . ale#Pad(l:compile_commands_option)
    \   . ale#Pad(ale#Var(a:buffer, 'c_cppcheck_options'))
    \   . l:buffer_path_include
    \   . ' %t'
endfunction

function! s:cpp_cppcheck_GetCommand(buffer) abort
    let l:cd_command = ale#handlers#cppcheck#GetCdCommand(a:buffer)
    let l:compile_commands_option = ale#handlers#cppcheck#GetCompileCommandsOptions(a:buffer)
    let l:buffer_path_include = empty(l:compile_commands_option)
    \   ? ale#handlers#cppcheck#GetBufferPathIncludeOptions(a:buffer)
    \   : ''

    if has('win32') || has('win16') || has('win95') || has('win64')
        let l:template = ' --template=^"{file}:{line}:{column}: {severity}:{inconclusive:inconclusive:} {message} [{id}]\\n{code}^"'
    else
        let l:template = ' --template=''{file}:{line}:{column}: {severity}:{inconclusive:inconclusive:} {message} [{id}]\\n{code}'''
    endif

    return l:cd_command
    \   . '%e -q --language=cpp'
    \   . l:template
    \   . ale#Pad(l:compile_commands_option)
    \   . ale#Pad(ale#Var(a:buffer, 'cpp_cppcheck_options'))
    \   . l:buffer_path_include
    \   . ' %t'
endfunction

call ale#linter#Define('c', {
			\   'name': 'cppcheck',
			\   'output_stream': 'both',
			\   'executable': {b -> ale#Var(b, 'c_cppcheck_executable')},
			\   'command': function('s:c_cppcheck_GetCommand'),
			\   'callback': 'ale#handlers#cppcheck#HandleCppCheckFormat',
			\})

call ale#linter#Define('cpp', {
			\   'name': 'cppcheck',
			\   'output_stream': 'both',
			\   'executable': {b -> ale#Var(b, 'cpp_cppcheck_executable')},
			\   'command': function('s:cpp_cppcheck_GetCommand'),
			\   'callback': 'ale#handlers#cppcheck#HandleCppCheckFormat',
			\})


