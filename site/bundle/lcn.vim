
let g:LanguageClient_loadSettings = 1
let g:LanguageClient_diagnosticsEnable = 0
let g:LanguageClient_settingsPath = expand('~/.vim/languageclient.json')
let g:LanguageClient_selectionUI = 'quickfix'
let g:LanguageClient_diagnosticsList = v:null
let g:LanguageClient_hoverPreview = 'Never'
" let g:LanguageClient_loggingLevel = 'DEBUG'
if !exists('g:LanguageClient_serverCommands')
	let g:LanguageClient_serverCommands = {}
	let g:LanguageClient_serverCommands.c = ['cquery']
	let g:LanguageClient_serverCommands.cpp = ['cquery']
endif
noremap <leader>rd :call LanguageClient#textDocument_definition({'gotoCmd':'FileSwitch tabe'})<cr>
noremap <leader>re :call LanguageClient#textDocument_definition({'gotoCmd':'PreviewFile'})<cr>
noremap <leader>rr :call LanguageClient#textDocument_references()<cr>
noremap <leader>rv :call LanguageClient#textDocument_hover()<cr>

