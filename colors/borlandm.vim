set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
set fillchars+=vert:║

let g:colors_name = "borlandm"

let s:vmode = "gui"
let s:none = "NONE"

if !exists("g:BorlandParen")
  let g:BorlandParen = 1
endif

if !exists("g:BorlandStyle")
  let g:BorlandStyle = "modern"
endif

if g:BorlandParen != 0
    autocmd! WinEnter * :if !exists('w:BorlandParenMatchId') | let w:BorlandParenMatchId=matchadd('Paren', '[(){}\[\]]') | endif
endif

if g:BorlandStyle == "classic"
  let s:darkblack = "#000000"
  let s:darkblue = "#0000a8"
  let s:darkgreen = "#00a800"
  let s:darkcyan = "#00a8a8"
  let s:darkred = "#a80000"
  let s:darkmagenta = "#a800a8"
  let s:darkyellow = "#a85700"
  let s:darkwhite = "#a8a8a8"
  let s:darkscroll = "#0038a8"
  let s:lightblack = "#575757"
  let s:lightblue = "#5757ff"
  let s:lightgreen = "#57ff57"
  let s:lightcyan = "#57ffff"
  let s:lightred = "#ff5757"
  let s:lightmagenta = "#ff57ff"
  let s:lightyellow = "#ffff57"
  let s:lightwhite = "#ffffff"
  let s:lightscroll = "#0070a8"
else
  let s:darkblack = "#000000"
  let s:darkblue = "#003078"
  let s:darkgreen = "#308800"
  let s:darkcyan = "#00a8a8"
  let s:darkred = "#a80000"
  let s:darkmagenta = "#a800a8"
  let s:darkyellow = "#a85700"
  let s:darkwhite = "#a8a8a8"
  let s:darkscroll = "#004078"
  let s:lightblack = "#575757"
  let s:lightblue = "#5757ff"
  let s:lightgreen = "#57ff57"
  let s:lightcyan = "#57ffff"
  let s:lightred = "#ff5757"
  let s:lightmagenta = "#ff57ff"
  let s:lightyellow = "#ffff57"
  let s:lightwhite = "#ffffff"
  let s:lightscroll = "#006078"
endif

let s:italic = "italic"
let s:bold = "bold"
let s:underline = "underline"
let s:undercurl = "undercurl"
let s:reverse = "reverse"
let s:standout = "standout"

function! s:setGroup(name, foreground, background, style)
  exe "hi! ".a:name." term=none cterm=none gui=none"
  exe "hi! ".a:name." ".s:vmode."fg=".a:foreground." ".s:vmode."bg=".a:background." ".s:vmode."=".a:style
endf

function! s:linkGroup(name, parent)
  exe "hi! def link ".a:name." ".a:parent
endf

" INFO Helper highlight groups

" NormalTransparent   like Normal, but with transparent background
call s:setGroup("NormalTransparent", s:lightyellow, s:none, s:none)

" INFO Vim default highlight groups

" ColorColumn   used for the columns set with 'colorcolumn'
call s:setGroup("ColorColumn", s:none, s:darkscroll, s:none)
" Conceal       placeholder characters substituted for concealed text (see 'conceallevel')
call s:linkGroup("Conceal", "Folded")
" Cursor        the character under the cursor (default: bg and fg reversed)
call s:setGroup("Cursor", s:none, s:none, s:reverse)
" CursorIM      like Cursor, but used when in IME mode |CursorIM|
call s:linkGroup("CursorIM", "Cursor")
" CursorColumn  the screen column that the cursor is in when 'cursorcolumn' is set
call s:linkGroup("CursorColumn", "ColorColumn")
" CursorLine    the screen line that the cursor is in when 'cursorline' is set
call s:linkGroup("CursorLine", "ColorColumn")
" Directory     directory names (and other special names in listings)
call s:linkGroup("Directory", "NormalTransparent")
" DiffAdd       diff mode: Added line |diff.txt|
" DiffChange    diff mode: Changed line |diff.txt|
" DiffDelete    diff mode: Deleted line |diff.txt|
" DiffText      diff mode: Changed text within a changed line |diff.txt|
" ExtraWhitespace trailing spaces and tabs (https://vim.fandom.com/wiki/Highlight_unwanted_spaces)
call s:linkGroup("ExtraWhitespace", "ColorColumn")
" EndOfBuffer   filler lines (~) after the last line in the buffer.  By default, this is highlighted like |hl-NonText|.
call s:linkGroup("EndOfBuffer", "NonText")
" ErrorMsg      error messages on the command line
call s:setGroup("ErrorMsg", s:lightyellow, s:darkred, s:none)
" VertSplit     the column separating vertically split windows
call s:linkGroup("VertSplit", "ModeMsg")
" Folded        line used for closed folds
call s:setGroup("Folded", s:darkblack, s:darkcyan, s:none)
" FoldColumn    'foldcolumn'
call s:linkGroup("FoldColumn", "Folded")
" SignColumn    column where |signs| are displayed
call s:linkGroup("SignColumn", "LineNr")
" IncSearch     'incsearch' highlighting; also used for the text replaced with ":s///c"
" LineNr        Line number for ":number" and ":#" commands, and when 'number' or 'relativenumber' option is set.
call s:setGroup("LineNr", s:darkcyan, s:none, s:none)
" CursorLineNr  Like LineNr when 'cursorline' or 'relativenumber' is set for the cursor line.
call s:linkGroup("CursorLineNr", "LineNr")
" MatchParen    The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
call s:setGroup("MatchParen", s:lightcyan, s:none, s:none)
" ModeMsg       'showmode' message (e.g., "-- INSERT --")
call s:setGroup("ModeMsg", s:lightwhite, s:none, s:none)
" MoreMsg       |more-prompt|
call s:linkGroup("MoreMsg", "ModeMsg")
" NonText       '@' at the end of the window, characters from 'showbreak' and other characters that do not really exist in the text (e.g., ">" displayed when a double-wide character doesn't fit at the end of the line).
call s:setGroup("NonText", s:darkcyan, s:none, s:none)
" Normal        normal text; any text that matches no syntax pattern
call s:setGroup("Normal", s:lightyellow, s:darkblue, s:none)
" Pmenu         Popup menu: normal item.
call s:setGroup("Pmenu", s:darkblack, s:darkcyan, s:none)
" PmenuSel      Popup menu: selected item.
call s:setGroup("PmenuSel", s:lightwhite, s:darkgreen, s:none)
" PmenuSbar     Popup menu: scrollbar.
call s:setGroup("PmenuSbar", s:darkscroll, s:lightscroll, s:none)
" PmenuThumb    Popup menu: Thumb of the scrollbar.
call s:setGroup("PmenuThumb", s:lightscroll, s:darkscroll, s:none)
" Question      |hit-enter| prompt and yes/no questions
call s:linkGroup("Question", "ModeMsg")
" QuickFixLine  Current |quickfix| item in the quickfix window.
" Search        Last search pattern highlighting (see 'hlsearch').  Also used for similar items that need to stand out.
" SpecialKey    Meta and special keys listed with ":map", also for text used to show unprintable characters in the text, 'listchars'.  Generally: text that is displayed differently from what it really is.
call s:setGroup("SpecialKey", s:lightcyan, s:none, s:none)
" SpellBad      Word that is not recognized by the spellchecker. |spell| This will be combined with the highlighting used otherwise.
" SpellCap      Word that should start with a capital. |spell| This will be combined with the highlighting used otherwise.
" SpellLocal    Word that is recognized by the spellchecker as one that is used in another region. |spell| This will be combined with the highlighting used otherwise.
" SpellRare     Word that is recognized by the spellchecker as one that is hardly ever used. |spell| This will be combined with the highlighting used otherwise.
" StatusLine    status line of current window
call s:setGroup("StatusLine", s:darkblack, s:darkgreen, s:none)
" StatusLineNC  status lines of not-current windows Note: if this is equal to "StatusLine" Vim will use "^^^" in the status line of the current window.
call s:setGroup("StatusLineNC", s:darkblack, s:darkwhite, s:none)
" TabLine       tab pages line, not active tab page label
call s:linkGroup("TabLine", "StatusLineNC")
" TabLineFill   tab pages line, where there are no labels
call s:linkGroup("TabLineFill", "TabLine")
" TabLineSel    tab pages line, active tab page label
call s:linkGroup("TabLineSel", "StatusLine")
" Title         titles for output from ":set all", ":autocmd" etc; Affects the window counter per tab
call s:linkGroup("Title", "NormalTransparent")
" Visual        Visual mode selection
call s:setGroup("Visual", s:darkblue, s:darkwhite, s:none)
" VisualNOS     Visual mode selection when vim is "Not Owning the Selection".  Only X11 Gui's |gui-x11| and |xterm-clipboard| supports this.
call s:setGroup("VisualNOS", s:darkblue, s:lightblack, s:none)
" WarningMsg    warning messages
call s:setGroup("WarningMsg", s:lightyellow, s:darkyellow, s:none)
" WildMenu      current match in 'wildmenu' completion
" CIf0          TODO what does this mean 

" INFO Recommended group names for syntax highlighting (:help group-names)

" Comment	         any comment
call s:setGroup("Comment", s:darkwhite, s:none, s:none)

" Constant	       any constant
call s:linkGroup("Constant", "NormalTransparent")
" String           a string constant: "this is a string"
call s:linkGroup("String", "Constant")
" Character        a character constant: 'c', '\n'
call s:linkGroup("Character", "Constant")
" Number           a number constant: 234, 0xff
call s:linkGroup("Number", "Constant")
" Boolean          a boolean constant: TRUE, false
call s:linkGroup("Boolean", "Constant")
" Float           a floating point constant: 2.3e10
call s:linkGroup("Float", "Constant")

" Identifier      any variable name
call s:linkGroup("Identifier", "NormalTransparent")

" Statement       any statement
call s:setGroup("Statement", s:lightwhite, s:none, s:none)
" Function        function statement
call s:linkGroup("Function", "Statement")
" Operator        "sizeof", "+", "*", etc.
call s:linkGroup("Operator", "Statement")
" Keyword         any other keyword
call s:linkGroup("Keyword", "Statement")
" Conditional     if, then, else, endif, switch, etc.
call s:linkGroup("Conditional", "Keyword")
" Repeat          for, do, while, etc.
call s:linkGroup("Repeat", "Keyword")
" Label           case, default, etc.
call s:linkGroup("Label", "Keyword")
" Exception       try, catch, throw
call s:linkGroup("Exception", "Keyword")

" Parenthesis     as matched by the AutoCmd at the top
call s:linkGroup("Paren", "Statement")

" Type            int, long, char, etc.
call s:setGroup("Type", s:lightwhite, s:none, s:none)
" StorageClass    static, register, volatile, etc.
call s:linkGroup("StorageClass", "Type")
" Structure       struct, union, enum, etc.
call s:linkGroup("Structure", "Type")
" Typedef         a typedef
call s:linkGroup("Typedef", "Type")

" PreProc         generic Preprocessor
call s:setGroup("PreProc", s:lightgreen, s:none, s:none)
" Include         preprocessor #include
call s:linkGroup("Include", "PreProc")
" Define          preprocessor #define
call s:linkGroup("Define", "PreProc")
" Macro           same as Define
call s:linkGroup("Macro", "PreProc")
" PreCondit       preprocessor #if, #else, #endif, etc.
call s:linkGroup("PreCondit", "PreProc")

" Special         any special symbol
call s:setGroup("Special", s:lightcyan, s:none, s:none)
" SpecialChar     special character in a constant
call s:linkGroup("SpecialChar", "Special")
" Tag             you can use CTRL-] on this
call s:linkGroup("Tag", "Special")
" Delimiter       character that needs attention
call s:linkGroup("Delimiter", "Special")
" SpecialComment  special things inside a comment
call s:linkGroup("SpecialComment", "Special")
" Debug           debugging statements
call s:linkGroup("Debug", "Special")

" Underlined      text that stands out, HTML links
call s:linkGroup("Underlined", "NormalTransparent")

" Ignore          left blank, hidden  |hl-Ignore|
call s:linkGroup("Ignore", "NormalTransparent")

" Error           any erroneous construct
call s:linkGroup("Error", "NormalTransparent")

" Todo            anything that needs extra attention; mostly the keywords TODO FIXME and XXX
call s:setGroup("Todo", s:lightred, s:none, s:none)

" INFO NERDTree colours

call s:setGroup("NERDTreeDir", s:lightcyan, s:darkblue, s:none)
call s:linkGroup("NERDTreePart", "NERDTreeDir")
call s:linkGroup("NERDTreePartFile", "NERDTreeDir")
call s:linkGroup("NERDTreeExecFile", "NERDTreeDir")
call s:linkGroup("NERDTreeDirSlash", "NERDTreeDir")
call s:linkGroup("NERDTreeBookmarksHeader", "NERDTreeDir")
call s:linkGroup("NERDTreeBookmarksLeader", "NERDTreeDir")
call s:linkGroup("NERDTreeBookmarkName", "NERDTreeDir")
call s:linkGroup("NERDTreeBookmark", "NERDTreeDir")
call s:linkGroup("NERDTreeToggleOn", "NERDTreeDir")
call s:linkGroup("NERDTreeToggleOff", "NERDTreeDir")
call s:linkGroup("NERDTreeLinkTarget", "NERDTreeDir")
call s:linkGroup("NERDTreeLinkFile", "NERDTreeDir")
call s:linkGroup("NERDTreeLinkDir", "NERDTreeDir")
call s:linkGroup("NERDTreeDir", "NERDTreeDir")
call s:linkGroup("NERDTreeUp", "NERDTreeDir")
call s:linkGroup("NERDTreeFile", "NERDTreeDir")
call s:linkGroup("NERDTreeCWD", "NERDTreeDir")
call s:linkGroup("NERDTreeOpenable", "NERDTreeDir")
call s:linkGroup("NERDTreeCloseable", "NERDTreeDir")
call s:linkGroup("NERDTreeIgnore", "NERDTreeDir")
call s:linkGroup("NERDTreeRO", "NERDTreeDir")
call s:linkGroup("NERDTreeFlags", "NERDTreeDir")
call s:linkGroup("NERDTreeCurrentNode", "NERDTreeDir")

call s:setGroup("NERDTreeHelp", s:lightyellow, s:darkblue, s:none)
call s:linkGroup("NERDTreeHelpKey", "NERDTreeHelp")
call s:linkGroup("NERDTreeHelpCommand", "NERDTreeHelp")
call s:linkGroup("NERDTreeHelpTitle", "NERDTreeHelp")

