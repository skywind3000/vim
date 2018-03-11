# vim-tips

Here's the tip database. Really fancy, right?

To add your own, just add a block like this:

    ```author
    First, add your name after the first ``` block. Don't add special chars here, please.

    Then just type your tip here :)

    You may add new lines or anything really, just make sure the tip is cool!
    ```

---

```jonatasbaldin
guu

Make the line lowercase.
```

```jonatasbaldin
gUU

Make the line uppercase.
```

```jonatasbaldin
gf

Open file name under the cursor.
```

```jonatasbaldin
ci(
or
ci)

Delete everything inside the parentheses and enter insert mode.
```

```vimtipsfortune
zz to center the cursor vertically on your screen. useful when you 250gzz, for instance.
```

```vimtipsfortune
git config --global core.editor "gvim --nofork"
```

```vimtipsfortune
ci" inside a " " will erase everything between "" and place you in insertion mode.
```

```vimtipsfortune
:set guifont=* in gvim or MacVim to get a font selection dialog. Useful while giving presentations.
```

```vimtipsfortune
:h slash<CTRL-d> to get a list of all help topics containing the word 'slash'.
```

```vimtipsfortune
guu converts entire line to lowercase. gUU converts entire line to uppercase. ~ inverts case of current character.
```

```vimtipsfortune
<CTRL-o> : trace your movements backwards in a file. <CTRL-i> trace your movements forwards in a file.
```

```vimtipsfortune
:ju(mps) : list your movements {{help|jump-motions}}
```

```vimtipsfortune
:history lists the history of your recent commands, sans duplicates.
```

```vimtipsfortune
"+y to copy to the X11 (or Windows) clipboard. "+p to paste from it.
```

```vimtipsfortune
2f/ would find the second occurrence of '/' in a line.
```

```vimtipsfortune
:tab sball will re-tab all files in the buffers list.
```

```vimtipsfortune
:%s/joe|fred/jerks/g will replace both 'fred' and 'joe' with 'jerks'.
```

```vimtipsfortune
* # g* g# each searches for the word under the cursor (forwards/backwards)
```

```vimtipsfortune
:vimgrep pattern **/*.txt will search all *.txt files in the current directory and its subdirectories for the pattern.
```

```vimtipsfortune
== will auto-indent the current line.  Select text in visual mode, then = to auto-indent the selected lines.
```

```vimtipsfortune
Count the number of occurences of a word in a file with :%s/<word>//gn
```

```vimtipsfortune
:set foldmethod=syntax to make editing long files of code much easier.  zo to open a fold.  zc to close it.  See more http://is.gd/9clX
```

```vimtipsfortune
Need to edit and run a previous command?  q: then find the command, edit it, and Enter to execute the line.
```

```vimtipsfortune
@: to repeat the last executed command.
```

```vimtipsfortune
:e $MYVIMRC to directly edit your vimrc.  :source $MYVIMRC to reload.  Mappings may make it even easier.
```

```vimtipsfortune
g<CTRL-G> to see technical information about the file, such as how many words are in it, or how many bytes it is.
```

```vimtipsfortune
gq{movement} to wrap text, or just gq while in visual mode. gqap will format the current paragraph.
```

```vimtipsfortune
:E to see a simple file explorer.  (:Ex will too, if that's easier to remember.)
```

```vimtipsfortune
:vimgrep pattern *.txt will search all .txt files in the current directory for the pattern.
```

```vimtipsfortune
:match ErrorMsg '\%>80v.\+' uses matching to highlight lines longer than 80 columns.
```

```vimtipsfortune
:%s/\r//g to remove all those nasty ^M from a file, or :%s/\r$//g for only at the end of a line.
```

```vimtipsfortune
% matches opening and closing chars (){}[], and with matchit.vim, def/end, HTML tags, etc. as well!
```

```vimtipsfortune
<CTRL-n><CTRL-p> offers word-completion while in insert mode.
```

```vimtipsfortune
<CTRL-x><CTRL-l> offers line completion in insert mode.
```

```vimtipsfortune
/<CTRL-r><CTRL-w> will pull the word under the cursor into search.
```

```vimtipsfortune
gf will open the file under the cursor.  (Killer feature.)
```

```vimtipsfortune
Ctrl-a, Ctrl-x will increment and decrement, respectively, the number under the cursor. May be precede by a count.
```

```vimtipsfortune
:scriptnames will list all plugins and _vimrcs loaded.
```

```vimtipsfortune
:tabdo [some command] will execute the command in all tabs.  Also see windo, bufdo, argdo.
```

```vimtipsfortune
:vsplit filename will split the window vertically and open the file in the left-hand pane.  Great when writing unit tests!
```

```vimtipsfortune
qa starts a recording in register 'a'. q stops it. @a repeats the recording. 5@a repeats it 5 times.
```

```vimtipsfortune
:%s/\v(.*\n){5}/&\r will insert a blank line every 5 lines
```

```vimtipsfortune
Ctrl-c to quickly get out of command-line mode.  (Faster than hitting ESC a couple times.)
```

```vimtipsfortune
Use '\v' in your regex to set the mode to 'very magic', and avoid confusion. (:h \v for more info.)
```

```vimtipsfortune
; is a motion to repeat last find with f. f' would find next quote. c; would change up to the next '
```

```vimtipsfortune
/\%>80v.\+ with search highlighting (:set hlsearch) will highlight any text after column 80.
```

```vimtipsfortune
ga will display the ASCII, hex, and octal value of the character under the cursor.
```

```vimtipsfortune
:%s/[.!?]\_s\+\a/\U&\E/g will uppercase the first letter of each sentence (except the very first one).
```

```vimtipsfortune
:r !date will insert the current date/time stamp (from the 'date' command -- a bit OS-specific).
```

```vimtipsfortune
:lcd %:p:h will change to the directory of the current file.
```

```vimtipsfortune
% matches brackets {} [] (), and with matchit.vim, also matches def/end, < ?php/?>, < p>/< /p>, etc.
```

```vimtipsfortune
:g/search_term/# display each line containing 'search_term' with line numbers.
```

```vimtipsfortune
:%s/<!--\_.\{-}-->// will delete HTML comments, potentially spanning multiple lines.
```

```vimtipsfortune
jumps to the last modified line. `. jumps to the exact position of last modification
```

```vimtipsfortune
[I (that's bracket open, capital i) show lines containing the word under the cursor.
```

```vimtipsfortune
:%s/\\/\//g replaces all backslashes with forward slashes
```

```vimtipsfortune
:vimgrep /stext/ **/*.txt | :copen searches for stext recursively in *.txt files and show results in separate window
```

```vimtipsfortune
ysiw' to surround current word with ',cs' {changes word to {word}} using the surround plugin: http://t.co/7QnLiwP3
```

```vimtipsfortune
use \v in your regex to set the mode to 'very magic' and avoid confusion (:h \v for more info) http://t.co/KWtRFNPI
```

```vimtipsfortune
in gvim, change the cursor depending on what mode you are (normal, insert, etc...) http://is.gd/9dq0
```

```vimtipsfortune
In visual mode, use " to surround the selected text with " using the surround plugin http://is.gd/fpwJQ
```

```vimtipsfortune
:tabo closes all tabs execpt the current one.
```

```vimtipsfortune
<C-U> / <C-D> move the cursor up/down half a page (also handy :set nosol)
```

```vimtipsfortune
:set titlestring=%f set the file name as the terminal title.
```

```vimtipsfortune
p / P paste after/before the cursor. Handy when inserting lines.
```

```vimtipsfortune
daw/caw deletes/changes the word under the cursor.
```

```vimtipsfortune
vim -d file1 file2 shows the differences between two files.
```

```vimtipsfortune
:set smartcase case sensitive if search contains an uppercase character and ignorecase is on.
```

```vimtipsfortune
:sh or :shell to open a console (then exit to come back to vim).
```

```vimtipsfortune
= : re-indent (e.g. == to re-indent the current line).
```

```vimtipsfortune
:%y c copies the entire buffer into register c. "cp inserts the content of register c in the current document.
```

```vimtipsfortune
ctrl-v blockwise visual mode (rectangular selection).
```

```vimtipsfortune
I/A switch to insert mode before/after the current line.
```

```vimtipsfortune
o/O insert a new line after/before the current line and switch to insert mode.
```

```vimtipsfortune
I/A in visual blockwise mode (ctrl-v) insert some text at the star/end of each line of the block text.
```

```vimtipsfortune
Need to edit a file in hex ? :help hex-editing gives you the manual.
```

```vimtipsfortune
Ctrl + o : Execute a command while in insert mode, then go back to insert mode. e.g. ctrl+o, p; paste without exiting insert mode
```

```vimtipsfortune
ctrl-r x (insert mode): insert the contents of buffer x. For example: "ctrl-r +" would insert the contents of the clipboard.
```

```vimtipsfortune
ctrl-r ctrl-w: Pull the word under the cursor in a : command. eg. :s/ctrl-r ctrl-w/foo/g
```

```vimtipsfortune
':%y c': yank entire file into register c. '"cp': Paste contents of c into document.
```

```vimtipsfortune
a/A : append at the cursor position / at the end of the line (enters insert mode)
```

```vimtipsfortune
ctrl-x ctrl-f (insert mode): complete with the file names in the current directory (ctrl-p/n to navigate through the candidates)
```

```vimtipsfortune
set mouse=a - enable mouse in terminal (selection, scroll, window resizing, ...).
```

```vimtipsfortune
J: join two lines
```

```vimtipsfortune
gg/G: go to start/end of file.
```

```vimtipsfortune
Ctrl-y (insert mode): insert character which is on the line above cursor. example: handy to initialize a structure.
```

```vimtipsfortune
:set nowrap - disable line wrapping
```

```vimtipsfortune
vim -p <files> - load all files listed in separate tabs. e.g. vim -p *.c
```

```vimtipsfortune
vmap out "zdmzO#if 0<ESC>"zp'zi#endif<CR><ESC> - macro to comment out a block of code using #if 0
```

```vimtipsfortune
<CTRT-W>v == :vsplit like <CTRL-w>s == :split
```

```vimtipsfortune
If gvim is started from a terminal it opens at the same width as the terminal. To prevent this, add "set columns=80" to ~/.vimrc
```

```vimtipsfortune
Prefixing G or gg (command mode) with a number will cause vim to jump to that line number.
```

```vimtipsfortune
set showbreak - set characters to prefix wrapped lines with. e.g. ":set showbreak=+++\ " (white space must be escaped)
```

```vimtipsfortune
When editing multiple files (e.g. vim *.c), use :n to move to the next file and :N to move to the previous file. :ar shows the list of files
```

```vimtipsfortune
:split - split the current window in two
```

```vimtipsfortune
vim --remote <file> - open a file in an existing vim session
```

```vimtipsfortune
A - enter insert mode at the end of the line (Append); I - insert before the first non-blank of the line
```

```vimtipsfortune
%< - resolves the current filename without extension. e.g. :e %<.h - open the header file for the current file
```

```vimtipsfortune
:set softtabstop <n> - set the number of spaces to insert when using the tab key (converted to tabs and spaces if expandtab is off).
```

```vimtipsfortune
:set expandtab - use spaces rather than the tab character to insert a tab.
```

```vimtipsfortune
:set guioptions - set various GUI vim options. e.g. to remove the menubar and toolbar, :set guioptions-=Tm
```

```vimtipsfortune
"vim - " - start vim and read from standard input. e.g. with syntax enabled, get a coloured diff from git: git diff | vim -
```

```vimtipsfortune
set mousemodel=popup - enable a popup menu on right click in GUI vim
```

```vimtipsfortune
r!cat - reads into the buffer from stdin and avoids using :set paste (use ctrl-d to finish)
```

```vimtipsfortune
:set title - display info in terminal title. Add let &titleold=getcwd() to .vimrc to set it to something useful on quit
```

```vimtipsfortune
:set pastetoggle=key - specify a key sequence that toggles the paste option, e.g. set pastetoggle=<F2>
```

```vimtipsfortune
:set paste - allows you to paste from the clipboard correctly, especially when vim is running in a terminal
```

```vimtipsfortune
substitute flag 'n' - count how many substitutions would be made, but don't actually make any 
```

```vimtipsfortune
set wildmenu - enhanced filename completion. left and right navigates matches; up and down navigates directories
```

```vimtipsfortune
zt, zz, zb: scroll so that the current position of the cursor is moved to the top, middle or bottom of the screen
```

```vimtipsfortune
[range]sort - sort the lines in the [range], or all lines if [range] is not given. e.g. :'<,'>sort - sort the current visual selection
```

```vimtipsfortune
%:exec ":new ".(substitute(expand("%"), ".c$", ".h", "")) - open the associated .h file for the current .c file in a new window; more concisely :new %:p:r.h
```

```vimtipsfortune
noh - stop highlighting the current search (if 'hlsearch' is enabled). Highlighting is automatically restored for the next search.
```

```vimtipsfortune
when substituting, \u makes just first character upper (like \l for lower) and \U is upper equivalent for \L
```

```vimtipsfortune
:retab <ts> - convert strings of white-space containing <Tab> with new strings using the <ts> value if given or current value of 'tabstop'
```

```vimtipsfortune
ctrl-v u <hex code> - enter a unicode character in insert mode
```

```vimtipsfortune
:set laststatus=2 - always show the status line (0 = never, 1 = (default) only if there are two or more windows, 2 = always)
```

```vimtipsfortune
b - go back a word (opposite of w)
```

```vimtipsfortune
} - move to the next blank line ( { - move to previous blank line)
```

```vimtipsfortune
s - delete characters and start insert mode (s stands for Substitute). e.g. 3s - delete three characters and start insert mode.
```

```vimtipsfortune
0 - Move to the first character of the line
```

```vimtipsfortune
:set columns=X - set the width of the window to X columns. For GUI vim, this is limited to the size of the screen
```

```vimtipsfortune
:only - close all windows except the current one (alternatives: ctrl-w ctrl-o or :on)
```

```vimtipsfortune
ctrl-<pagedown> / ctrl-<pageup> - switch to next/previous tab. (alternatives: gt/gT, :tabn/:tabp, etc)
```

```vimtipsfortune
:tabe <filename> - open <filename> in a new tab (same as :tabedit and :tabnew)
```

```vimtipsfortune
Ctrl-T and Ctrl-D - indent and un-indent the current line in insert mode
```

```vimtipsfortune
vim +<num> - start vim and place the cursor on line <lnum>. If lnum is not specified, start at the end of the file
```

```vimtipsfortune
gj, gk (or g<Up> g<Down>) - move up or down a display line (makes a difference for wrapped lines)
```

```vimtipsfortune
>{motion} and <{motion} - (normal mode) increase/decrease the current indent. e.g. << - decrease the indent of the current line
```

```vimtipsfortune
"+ and "* - clipboard and current selection registers under X. e.g. "+p to paste from the clipboard and "+y to copy to the clipboard
```

```vimtipsfortune
:r!<cmd> - insert the result of <cmd> into the current buffer at the cursor. e.g. :r!ls *.h
```

```vimtipsfortune
& - re-run last :s command (&& to remember flags)
```

```vimtipsfortune
set wildignore - ignore matching files when using tab complete on filenames. e.g. :set wildignore=*.o,*.lo
```

```vimtipsfortune
CTRL-V <tab> - in insert mode, enters a real tab character, disregarding tab and indent options
```

```vimtipsfortune
CTRL-U/CTRL-D - scroll up/down, moving the cursor the same number of lines if possible (unlike <PageUp>/<PageDown>)
```

```vimtipsfortune
:set cursorline - Highlight the current line under the cursor
```

```vimtipsfortune
:set showcmd - show the number of lines/chacters in a visual selection
```

```vimtipsfortune
:x is like ":wq", but write only when changes have been made
```

```vimtipsfortune
ctrl-b / ctrl-f : page up / page down
```

```vimtipsfortune
ctrl-clic / ctrl-t : go to symbol definition (= ctrl-]) (using tags) and back. You can use "make tags" autotooled projects to create tags
```

```vimtipsfortune
0/joe/+3 -- find joe move cursor 3 lines down
```

```vimtipsfortune
/^joe.*fred.*bill/ -- find joe AND fred AND Bill (Joe at start of line)
```

```vimtipsfortune
/^[A-J]/ -- search for lines beginning with one or more A-J
```

```vimtipsfortune
/begin\_.*end -- search over possible multiple lines
```

```vimtipsfortune
/fred\_s*joe/ -- any whitespace including newline [C]
```

```vimtipsfortune
/fred\|joe -- Search for FRED OR JOE
```

```vimtipsfortune
/.*fred\&.*joe -- Search for FRED AND JOE in any ORDER!
```

```vimtipsfortune
/\<fred\>/ -- search for fred but not alfred or frederick [C]
```

```vimtipsfortune
/\<\d\d\d\d\> -- Search for exactly 4 digit numbers
```

```vimtipsfortune
/\D\d\d\d\d\D -- Search for exactly 4 digit numbers
```

```vimtipsfortune
/\<\d\{4}\> -- same thing
```

```vimtipsfortune
/\([^0-9]\|^\)%.*% -- Search for absence of a digit or beginning of line
```

```vimtipsfortune
/^\n\{3} -- find 3 empty lines -- finding empty lines
```

```vimtipsfortune
/^str.*\nstr -- find 2 successive lines starting with str
```

```vimtipsfortune
/\(^str.*\n\)\{2} -- find 2 successive lines starting with str
```

```vimtipsfortune
/\(fred\).*\(joe\).*\2.*\1 -- using rexexp memory in a search find fred.*joe.*joe.*fred *C*
```

```vimtipsfortune
/^\([^,]*,\)\{8} -- Repeating the Regexp (rather than what the Regexp finds)
```

```vimtipsfortune
:vmap // y/<C-R>"<CR> -- search for visually highlighted text -- visual searching
```

```vimtipsfortune
:vmap <silent> //    y/<C-R>=escape(@", '\\/.*$^~[]')<CR><CR> -- with spec chars
```

```vimtipsfortune
/<\zs[^>]*\ze> -- search for tag contents, ignoring chevrons -- \zs and \ze regex delimiters :h /\zs
```

```vimtipsfortune
/<\@<=[^>]*>\@= -- search for tag contents, ignoring chevrons -- zero-width :h /\@=
```

```vimtipsfortune
/<\@<=\_[^>]*>\@= -- search for tags across possible multiple lines
```

```vimtipsfortune
/<!--\_p\{-}--> -- search for multiple line comments -- searching over multiple lines \_ means including newline
```

```vimtipsfortune
/fred\_s*joe/ -- any whitespace including newline *C*
```

```vimtipsfortune
/bugs\(\_.\)*bunny -- bugs followed by bunny anywhere in file
```

```vimtipsfortune
:h \_ -- help
```

```vimtipsfortune
:nmap gx yiw/^\(sub\<bar>function\)\s\+<C-R>"<CR> -- search for declaration of subroutine/function under cursor
```

```vimtipsfortune
:bufdo /searchstr/ -- use :rewind to recommence search -- multiple file search
```

```vimtipsfortune
:bufdo %s/searchstr/&/gic -- say n and then a to stop -- multiple file search better but cheating
```

```vimtipsfortune
?http://www.vim.org/ -- (first) search BACKWARDS!!! clever huh!  -- How to search for a URL without backslashing
```

```vimtipsfortune
/\c\v([^aeiou]&\a){4} -- search for 4 consecutive consonants -- Specify what you are NOT searching for (vowels)
```

```vimtipsfortune
/\%>20l\%<30lgoat -- Search for goat between lines 20 and 30 [N]
```

```vimtipsfortune
/^.\{-}home.\{-}\zshome/e -- match only the 2nd occurence in a line of "home" [N]
```

```vimtipsfortune
:%s/home.\{-}\zshome/alone -- Substitute only the occurrence of home in any line [N]
```

```vimtipsfortune
^\(.*tongue.*\)\@!.*nose.*$ -- find str but not on lines containing tongue
```

```vimtipsfortune
\v^((tongue)@!.)*nose((tongue)@!.)*$
```

```vimtipsfortune
.*nose.*\&^\%(\%(tongue\)\@!.\)*$ 
```

```vimtipsfortune
:v/tongue/s/nose/&/gic
```

```vimtipsfortune
:%s/fred/joe/igc -- general substitute command -- *best-substitution*
```

```vimtipsfortune
:%s//joe/igc -- Substitute what you last searched for [N]
```

```vimtipsfortune
:%s/~/sue/igc -- Substitute your last replacement string [N]
```

```vimtipsfortune
:%s/\r//g -- Delete DOS returns ^M
```

```vimtipsfortune
:%s/\r/\r/g -- Turn DOS returns ^M into real returns -- Is your Text File jumbled onto one line? use following
```

```vimtipsfortune
:%s=  *$== -- delete end of line blanks
```

```vimtipsfortune
:%s= \+$== -- Same thing
```

```vimtipsfortune
:%s#\s*\r\?$## -- Clean both trailing spaces AND DOS returns
```

```vimtipsfortune
:%s#\s*\r*$## -- same thing
```

```vimtipsfortune
:%s/^\n\{3}// -- delete blocks of 3 empty lines -- deleting empty lines
```

```vimtipsfortune
:%s/^\n\+/\r/ -- compressing empty lines
```

```vimtipsfortune
:%s#<[^>]\+>##g -- delete html tags, leave text (non-greedy)
```

```vimtipsfortune
:%s#<\_.\{-1,}>##g -- delete html tags possibly multi-line (non-greedy)
```

```vimtipsfortune
:%s#.*\(\d\+hours\).*#\1# -- Delete all but memorised string (\1) [N]
```

```vimtipsfortune
%s#><\([^/]\)#>\r<\1#g -- split jumbled up XML file into one tag per line [N]
```

```vimtipsfortune
:'a,'bg/fred/s/dick/joe/igc -- VERY USEFUL -- VIM Power Substitute
```

```vimtipsfortune
:%s= [^ ]\+$=&&= -- duplicate end column -- duplicating columns
```

```vimtipsfortune
:%s= \f\+$=&&= -- same thing
```

```vimtipsfortune
:%s= \S\+$=&& -- usually the same
```

```vimtipsfortune
:%s#example#& = &#gic -- duplicate entire matched string [N] -- memory
```

```vimtipsfortune
:%s#.*\(tbl_\w\+\).*#\1# -- extract list of all strings tbl_* from text  [NC]
```

```vimtipsfortune
:s/\(.*\):\(.*\)/\2 -- \1/   : reverse fields separated by :
```

```vimtipsfortune
:%s/^\(.*\)\n\1$/\1/ -- delete duplicate lines
```

```vimtipsfortune
:%s/^\(.*\)\(\n\1\)\+$/\1/ -- delete multiple duplicate lines [N]
```

```vimtipsfortune
:%s/^.\{-}pdf/new.pdf/ -- delete to 1st occurence of pdf only (non-greedy) -- non-greedy matching \{-}
```

```vimtipsfortune
:%s#\<[zy]\?tbl_[a-z_]\+\>#\L&#gc -- lowercase with optional leading characters -- use of optional atom \?
```

```vimtipsfortune
:%s/<!--\_.\{-}-->// -- delete possibly multi-line comments -- over possibly many lines
```

```vimtipsfortune
:help /\{-} -- help non-greedy
```

```vimtipsfortune
:s/fred/<c-r>a/g -- sub "fred" with contents of register "a" -- substitute using a register
```

```vimtipsfortune
:s/fred/<c-r>asome_text<c-r>s/g  
```

```vimtipsfortune
:s/fred/\=@a/g -- better alternative as register not displayed (not *) [C]
```

```vimtipsfortune
:%s/\f\+\.gif\>/\r&\r/g | v/\.gif$/d | %s/gif/jpg/ -- multiple commands on one line
```

```vimtipsfortune
:%s/a/but/gie|:update|:next -- then use @: to repeat
```

```vimtipsfortune
:%s/goat\|cow/sheep/gc -- ORing (must break pipe) -- ORing
```

```vimtipsfortune
:'a,'bs#\[\|\]##g -- remove [] from lines between markers a and b [N]
```

```vimtipsfortune
:%s/\v(.*\n){5}/&\r -- insert a blank line every 5 lines [N]
```

```vimtipsfortune
:s/__date__/\=strftime("%c")/ -- insert datestring -- Calling a VIM function
```

```vimtipsfortune
:inoremap \zd <C-R>=strftime("%d%b%y")<CR> -- insert date eg 31Jan11 [N]
```

```vimtipsfortune
:%s:\(\(\w\+\s\+\)\{2}\)str1:\1str2: -- Working with Columns sub any str1 in col3
```

```vimtipsfortune
:%s:\(\w\+\)\(.*\s\+\)\(\w\+\)$:\3\2\1: -- Swapping first & last column (4 columns)
```

```vimtipsfortune
:%s#\<from\>\|\<where\>\|\<left join\>\|\<\inner join\>#\r&#g -- format a mysql query 
```

```vimtipsfortune
:redir @*|sil exec 'g#<\(input\|select\|textarea\|/\=form\)\>#p'|redir END -- filter all form elements into paste register
```

```vimtipsfortune
:nmap ,z :redir @*<Bar>sil exec 'g@<\(input\<Bar>select\<Bar>textarea\<Bar>/\=form\)\>@p'<Bar>redir END<CR>
```

```vimtipsfortune
:%s/^\(.\{30\}\)xx/\1yy/ -- substitute string in column 30 [N]
```

```vimtipsfortune
:%s/\d\+/\=(submatch(0)-3)/ -- decrement numbers by 3
```

```vimtipsfortune
:g/loc\|function/s/\d/\=submatch(0)+6/ -- increment numbers by 6 on certain lines only
```

```vimtipsfortune
:%s#txtdev\zs\d#\=submatch(0)+1#g -- better
```

```vimtipsfortune
:h /\zs
```

```vimtipsfortune
:%s/\(gg\)\@<=\d\+/\=submatch(0)+6/ -- increment only numbers gg\d\d  by 6 (another way)
```

```vimtipsfortune
:h zero-width
```

```vimtipsfortune
:let i=10 | 'a,'bg/Abc/s/yy/\=i/ |let i=i+1 # convert yy to 10,11,12 etc -- rename a string with an incrementing number
```

```vimtipsfortune
:let i=10 | 'a,'bg/Abc/s/xx\zsyy\ze/\=i/ |let i=i+1 # convert xxyy to xx11,xx12,xx13 -- as above but more precise
```

```vimtipsfortune
:%s/"\([^.]\+\).*\zsxx/\1/ -- find replacement text, put in memory, then use \zs to simplify substitute
```

```vimtipsfortune
:nmap <leader>z :%s#\<<c-r>=expand("<cword>")<cr>\># -- Pull word under cursor into LHS of a substitute
```

```vimtipsfortune
:vmap <leader>z :<C-U>%s/\<<c-r>*\>/ -- Pull Visually Highlighted text into LHS of a substitute
```

```vimtipsfortune
:'a,'bs/bucket\(s\)*/bowl\1/gic   [N] -- substitute singular or plural
```

```vimtipsfortune
:%s,\(all/.*\)\@<=/,_,g -- replace all / with _ AFTER "all/"
```

```vimtipsfortune
:s#all/\zs.*#\=substitute(submatch(0), '/', '_', 'g')# -- Same thing
```

```vimtipsfortune
:s#all/#&^M#|s#/#_#g|-j!  -- Substitute by splitting line, then re-joining
```

```vimtipsfortune
:%s/.*/\='cp '.submatch(0).' all/'.substitute(submatch(0),'/','_','g')/ -- Substitute inside substitute
```

```vimtipsfortune
:g/gladiolli/# -- display with line numbers (YOU WANT THIS!) -- *best-global* command 
```

```vimtipsfortune
:g/fred.*joe.*dick/ -- display all lines fred,joe & dick
```

```vimtipsfortune
:g/\<fred\>/ -- display all lines fred but not freddy
```

```vimtipsfortune
:g/^\s*$/d -- delete all blank lines
```

```vimtipsfortune
:g!/^dd/d -- delete lines not containing string
```

```vimtipsfortune
:v/^dd/d -- delete lines not containing string
```

```vimtipsfortune
:g/joe/,/fred/d -- not line based (very powerfull)
```

```vimtipsfortune
:g/fred/,/joe/j -- Join Lines [N]
```

```vimtipsfortune
:g/{/ ,/}/- s/\n\+/\r/g -- Delete empty lines but only between {...}
```

```vimtipsfortune
:v/\S/d -- Delete empty lines (and blank lines ie whitespace)
```

```vimtipsfortune
:v/./,/./-j -- compress empty lines
```

```vimtipsfortune
:g/^$/,/./-j -- compress empty lines
```

```vimtipsfortune
:g/<input\|<form/p -- ORing
```

```vimtipsfortune
:g/^/put_ -- double space file (pu = put)
```

```vimtipsfortune
:g/^/m0 -- Reverse file (m = move)
```

```vimtipsfortune
:g/^/m$ -- No effect! [N]
```

```vimtipsfortune
:'a,'bg/^/m'b -- Reverse a section a to b
```

```vimtipsfortune
:g/^/t. -- duplicate every line
```

```vimtipsfortune
:g/fred/t$ -- copy (transfer) lines matching fred to EOF
```

```vimtipsfortune
:g/stage/t'a -- copy (transfer) lines matching stage to marker a (cannot use .) [C]
```

```vimtipsfortune
:g/^Chapter/t.|s/./-/g -- Automatically underline selecting headings [N]
```

```vimtipsfortune
:g/\(^I[^^I]*\)\{80}/d -- delete all lines containing at least 80 tabs
```

```vimtipsfortune
:g/^/ if line('.')%2|s/^/zz / -- perform a substitute on every other line
```

```vimtipsfortune
:'a,'bg/somestr/co/otherstr/ -- co(py) or mo(ve)
```

```vimtipsfortune
:'a,'bg/str1/s/str1/&&&/|mo/str2/ copy or move or substitute
```

```vimtipsfortune
:%norm jdd -- delete every other line
```

```vimtipsfortune
:.,$g/^\d/exe "norm! \<c-a>" -- increment numbers
```

```vimtipsfortune
:'a,'bg/\d\+/norm! ^A -- increment numbers
```

```vimtipsfortune
:g/fred/y A -- append all lines fred to register a
```

```vimtipsfortune
:g/fred/y A | :let @*=@a -- put into paste buffer
```

```vimtipsfortune
:let @a=''|g/Barratt/y A |:let @*=@a
```

```vimtipsfortune
:'a,'bg/^Error/ . w >> errors.txt -- filter lines to a file (file must already exist)
```

```vimtipsfortune
:g/./yank|put|-1s/'/"/g|s/.*/Print '&'/ -- duplicate every line in a file wrap a print '' around each duplicate
```

```vimtipsfortune
:g/^MARK$/r tmp.txt | -d -- replace string with contents of a file, -d deletes the "mark"
```

```vimtipsfortune
:g/<pattern>/z#.5 -- display with context -- display prettily
```

```vimtipsfortune
:g/<pattern>/z#.5|echo "==========" -- display beautifully
```

```vimtipsfortune
:g/|/norm 2f|r* -- replace 2nd | with a star -- Combining g// with normal mode commands
```

```vimtipsfortune
:nmap <F3>  :redir @a<CR>:g//<CR>:redir END<CR>:new<CR>:put! a<CR><CR> -- send output of previous global command to a new window
```

```vimtipsfortune
:'a,'bg/fred/s/joe/susan/gic --  can use memory to extend matching -- *Best-Global-combined-with-substitute* (*power-editing*)
```

```vimtipsfortune
:/fred/,/joe/s/fred/joe/gic --  non-line based (ultra)
```

```vimtipsfortune
:/biz/,/any/g/article/s/wheel/bucket/gic:  non-line based [N]
```

```vimtipsfortune
:/fred/;/joe/-2,/sid/+3s/sally/alley/gIC -- Find fred before beginning search for joe
```

```vimtipsfortune
:g/^/exe ".w ".line(".").".txt" -- create a new file for each line of file eg 1.txt,2.txt,3,txt etc
```

```vimtipsfortune
:.g/^/ exe ".!sed 's/N/X/'" | s/I/Q/    [N] -- chain an external command
```

```vimtipsfortune
d/fred/                                :delete until fred -- Operate until string found [N]
```

```vimtipsfortune
y/fred/                                :yank until fred
```

```vimtipsfortune
c/fred/e                               :change until fred end
```

```vimtipsfortune
.      last edit (magic dot) -- Summary of editing repeats [N]
```

```vimtipsfortune
:&     last substitute
```

```vimtipsfortune
:%&    last substitute every line
```

```vimtipsfortune
:%&gic last substitute every line confirm
```

```vimtipsfortune
g%     normal mode repeat last substitute
```

```vimtipsfortune
g&     last substitute on all lines
```

```vimtipsfortune
@@     last recording
```

```vimtipsfortune
@:     last command-mode command
```

```vimtipsfortune
:!!    last :! command
```

```vimtipsfortune
:~     last substitute
```

```vimtipsfortune
:help repeating
```

```vimtipsfortune
;      last f, t, F or T -- Summary of repeated searches
```

```vimtipsfortune
,      last f, t, F or T in opposite direction
```

```vimtipsfortune
n      last / or ? search
```

```vimtipsfortune
N      last / or ? search in opposite direction
```

```vimtipsfortune
* # g* g# -- find word under cursor (<cword>) (forwards/backwards)
```

```vimtipsfortune
% -- match brackets {}[]()
```

```vimtipsfortune
. -- repeat last modification 
```

```vimtipsfortune
@: -- repeat last : command (then @@)
```

```vimtipsfortune
matchit.vim -- % now matches tags <tr><td><script> <?php etc
```

```vimtipsfortune
<C-N><C-P> -- word completion in insert mode
```

```vimtipsfortune
<C-X><C-L> -- Line complete SUPER USEFUL
```

```vimtipsfortune
/<C-R><C-W> -- Pull <cword> onto search/command line
```

```vimtipsfortune
/<C-R><C-A> -- Pull <CWORD> onto search/command line
```

```vimtipsfortune
:set ignorecase -- you nearly always want this
```

```vimtipsfortune
:set smartcase -- overrides ignorecase if uppercase used in search string (cool)
```

```vimtipsfortune
:syntax on -- colour syntax in Perl,HTML,PHP etc
```

```vimtipsfortune
:set syntax=perl -- force syntax (usually taken from file extension)
```

```vimtipsfortune
:h regexp<C-D> -- type control-D and get a list all help topics containing regexp (plus use TAB to Step thru list)
```

```vimtipsfortune
:nmap ,s :source $VIM/_vimrc -- MAKE IT EASY TO UPDATE/RELOAD _vimrc
```

```vimtipsfortune
:nmap ,v :e $VIM/_vimrc
```

```vimtipsfortune
:e $MYVIMRC -- edits your _vimrc whereever it might be  [N]
```

```vimtipsfortune
:vsplit other.php       # vertically split current file with other.php [N] -- splitting windows
```

```vimtipsfortune
:vmap sb "zdi<b><C-R>z</b><ESC> -- wrap <b></b> around VISUALLY selected Text
```

```vimtipsfortune
:vmap st "zdi<?= <C-R>z ?><ESC> -- wrap <?=   ?> around VISUALLY selected Text
```

```vimtipsfortune
vim -p fred.php joe.php -- open files in tabs
```

```vimtipsfortune
:tabe fred.php -- open fred.php in a new tab
```

```vimtipsfortune
:tab ball -- tab open files
```

```vimtipsfortune
:close -- close a tab but leave the buffer *N*
```

```vimtipsfortune
:nnoremap gf <C-W>gf -- vim 7 forcing use of tabs from .vimrc
```

```vimtipsfortune
:cab      e  tabe
```

```vimtipsfortune
:tab sball -- retab all files in buffer (repair) [N]
```

```vimtipsfortune
:e . -- file explorer -- Exploring
```

```vimtipsfortune
:Exp(lore) -- file explorer note capital Ex
```

```vimtipsfortune
:Sex(plore) -- file explorer in split window
```

```vimtipsfortune
:browse e -- windows style browser
```

```vimtipsfortune
:ls -- list of buffers
```

```vimtipsfortune
:cd .. -- move to parent directory
```

```vimtipsfortune
:args -- list of files
```

```vimtipsfortune
:pwd -- Print Working Directory (current directory) [N]
```

```vimtipsfortune
:args *.php -- open list of files (you need this!)
```

```vimtipsfortune
:lcd %:p:h -- change to directory of current file
```

```vimtipsfortune
:autocmd BufEnter * lcd %:p:h -- change to directory of current file automatically (put in _vimrc)
```

```vimtipsfortune
guu -- lowercase line -- Changing Case
```

```vimtipsfortune
gUU -- uppercase line
```

```vimtipsfortune
Vu -- lowercase line
```

```vimtipsfortune
VU -- uppercase line
```

```vimtipsfortune
g~~ -- flip case line
```

```vimtipsfortune
vEU -- Upper Case Word
```

```vimtipsfortune
vE~ -- Flip Case Word
```

```vimtipsfortune
ggguG -- lowercase entire file
```

```vimtipsfortune
vmap ,c :s/\<\(.\)\(\k*\)\>/\u\1\L\2/g<CR> -- Titlise Visually Selected Text (map for .vimrc)
```

```vimtipsfortune
vnoremap <F6> :s/\%V\<\(\w\)\(\w*\)\>/\u\1\L\2/ge<cr> [N] -- Title Case A Line Or Selection (better)
```

```vimtipsfortune
nmap ,t :s/.*/\L&/<bar>:s/\<./\u&/g<cr>  [N] -- titlise a line
```

```vimtipsfortune
:%s/[.!?]\_s\+\a/\U&\E/g -- Uppercase first letter of sentences
```

```vimtipsfortune
gf -- open file name under cursor (SUPER)
```

```vimtipsfortune
:nnoremap gF :view <cfile><cr> -- open file under cursor, create if necessary
```

```vimtipsfortune
ga -- display hex,ascii value of char under cursor
```

```vimtipsfortune
ggg?G -- rot13 whole file (quicker for large file)
```

```vimtipsfortune
:8 | normal VGg? -- rot13 from line 8
```

```vimtipsfortune
:normal 10GVGg? -- rot13 from line 8
```

```vimtipsfortune
<C-A>,<C-X> -- increment,decrement number under cursor
```

```vimtipsfortune
win32 users must remap CNTRL-A
```

```vimtipsfortune
<C-R>=5*5 -- insert 25 into text (mini-calculator)
```

```vimtipsfortune
:h 42 -- also http://www.google.com/search?q=42 -- Make all other tips superfluous
```

```vimtipsfortune
:h holy-grail
```

```vimtipsfortune
:h!
```

```vimtipsfortune
ggVGg? -- rot13 whole file (toggles) -- disguise text (watch out) [N]
```

```vimtipsfortune
:set rl! -- reverse lines right to left (toggles)
```

```vimtipsfortune
:g/^/m0 -- reverse lines top to bottom (toggles)
```

```vimtipsfortune
:%s/\(\<.\{-}\>\)/\=join(reverse(split(submatch(1), '.\zs')), '')/g -- reverse all text *N*
```

```vimtipsfortune
g; -- cycle thru recent changes (oldest first)
```

```vimtipsfortune
g, -- reverse direction 
```

```vimtipsfortune
:changes
```

```vimtipsfortune
:h changelist -- help for above
```

```vimtipsfortune
:help jump-motions
```

```vimtipsfortune
:history -- list of all your commands
```

```vimtipsfortune
:his c -- commandline history
```

```vimtipsfortune
:his s -- search history
```

```vimtipsfortune
q/ -- Search history Window (puts you in full edit mode) (exit CTRL-C)
```

```vimtipsfortune
q: -- commandline history Window (puts you in full edit mode) (exit CTRL-C)
```

```vimtipsfortune
:<C-F> -- history Window (exit CTRL-C)
```

```vimtipsfortune
:map   <f7>   :'a,'bw! c:/aaa/x -- save text to file x
```

```vimtipsfortune
:map   <f8>   :r c:/aaa/x -- retrieve text 
```

```vimtipsfortune
:map   <f11>  :.w! c:/aaa/xr<CR> -- store current line
```

```vimtipsfortune
:map   <f12>  :r c:/aaa/xr<CR> -- retrieve current line
```

```vimtipsfortune
:ab php -- list of abbreviations beginning php
```

```vimtipsfortune
:map , -- list of maps beginning ,
```

```vimtipsfortune
set wak=no -- :h winaltkeys -- allow use of F10 for mapping (win32)
```

```vimtipsfortune
<CR> -- carriage Return for maps -- For use in Maps
```

```vimtipsfortune
<ESC> -- Escape
```

```vimtipsfortune
<LEADER> -- normally \
```

```vimtipsfortune
<BAR> -- | pipe
```

```vimtipsfortune
<BACKSPACE> -- backspace
```

```vimtipsfortune
<SILENT> -- No hanging shell window
```

```vimtipsfortune
:nmap <leader>c :hi Normal guibg=#<c-r>=expand("<cword>")<cr><cr> -- display RGB colour under the cursor eg #445588
```

```vimtipsfortune
map <f2> /price only\\|versus/ :in a map need to backslash the \
```

```vimtipsfortune
imap ,,, <esc>bdwa<<esc>pa><cr></<esc>pa><esc>kA -- type table,,, to get <table></table>       ### Cool ###
```

```vimtipsfortune
:for i in range(1, 12) | execute("map <F".i.">") | endfor   [N] -- list current mappings of all your function keys
```

```vimtipsfortune
:cab ,f :for i in range(1, 12) \| execute("map <F".i.">") \| endfor -- for your .vimrc
```

```vimtipsfortune
iab phpdb exit("<hr>Debug <C-R>a  "); -- Simple PHP debugging display all variables yanked into register a
```

```vimtipsfortune
:let @m=":'a,'bs/" -- Using a register as a map (preload registers in .vimrc)
```

```vimtipsfortune
:let @s=":%!sort -u"
```

```vimtipsfortune
"ayy@a -- execute "Vim command" in a text file -- Useful tricks
```

```vimtipsfortune
yy@" -- same thing using unnamed register
```

```vimtipsfortune
u@. -- execute command JUST typed in
```

```vimtipsfortune
"ddw -- store what you delete in register d [N]
```

```vimtipsfortune
"ccaw -- store what you change in register c [N]
```

```vimtipsfortune
:r!ls -R -- reads in output of ls -- Get output from other commands (requires external programs)
```

```vimtipsfortune
:put=glob('**') -- same as above                 [N]
```

```vimtipsfortune
:r !grep "^ebay" file.txt -- grepping in content   [N]
```

```vimtipsfortune
:20,25 !rot13 -- rot13 lines 20 to 25   [N]
```

```vimtipsfortune
!!date -- same thing (but replaces/filters current line)
```

```vimtipsfortune
:%!sort -u -- use an external program to filter content -- Sorting with external sort
```

```vimtipsfortune
:'a,'b!sort -u -- use an external program to filter content
```

```vimtipsfortune
!1} sort -u -- sorts paragraph (note normal mode!!)
```

```vimtipsfortune
:g/^$/;/^$/-1!sort -- Sort each block (note the crucial ;)
```

```vimtipsfortune
:sort /.*\%2v/ -- sort all lines on second column [N] -- Sorting with internal sort
```

```vimtipsfortune
:new | r!nl #                  [N] -- number lines  (linux or cygwin only)
```

```vimtipsfortune
:bn -- goto next buffer -- Multiple Files Management (Essential)
```

```vimtipsfortune
:bp -- goto previous buffer
```

```vimtipsfortune
:wn -- save file and move to next (super)
```

```vimtipsfortune
:wp -- save file and move to previous
```

```vimtipsfortune
:bd -- remove file from buffer list (super)
```

```vimtipsfortune
:bun -- Buffer unload (remove window but not from list)
```

```vimtipsfortune
:badd file.c -- file from buffer list
```

```vimtipsfortune
:b3 -- go to buffer 3 [C]
```

```vimtipsfortune
:b main -- go to buffer with main in name eg main.c (ultra)
```

```vimtipsfortune
:sav php.html -- Save current file as php.html and "move" to php.html
```

```vimtipsfortune
:sav! %<.bak -- Save Current file to alternative extension (old way)
```

```vimtipsfortune
:sav! %:r.cfm -- Save Current file to alternative extension
```

```vimtipsfortune
:sav %:s/fred/joe/ -- do a substitute on file name
```

```vimtipsfortune
:sav %:s/fred/joe/:r.bak2 -- do a substitute on file name & ext.
```

```vimtipsfortune
:!mv % %:r.bak -- rename current file (DOS use Rename or DEL)
```

```vimtipsfortune
:help filename-modifiers
```

```vimtipsfortune
:e! -- return to unmodified file
```

```vimtipsfortune
:w c:/aaa/% -- save file elsewhere
```

```vimtipsfortune
:e # -- edit alternative file (also cntrl-^)
```

```vimtipsfortune
:rew -- return to beginning of edited files list (:args)
```

```vimtipsfortune
:brew -- buffer rewind
```

```vimtipsfortune
:sp fred.txt -- open fred.txt into a split
```

```vimtipsfortune
:sball,:sb -- Split all buffers (super)
```

```vimtipsfortune
:scrollbind -- in each split window
```

```vimtipsfortune
:map   <F5> :ls<CR>:e # -- Pressing F5 lists all buffer, just type number
```

```vimtipsfortune
:set hidden -- Allows to change buffer w/o saving current buffer
```

```vimtipsfortune
map <C-J> <C-W>j<C-W>_ -- Quick jumping between splits
```

```vimtipsfortune
map <C-K> <C-W>k<C-W>_
```

```vimtipsfortune
@@ -- Repeat a macro
```

```vimtipsfortune
5@@ -- Repeat a macro 5 times
```

```vimtipsfortune
qQ@qq -- Make an existing recording q recursive [N]
```

```vimtipsfortune
"qp --display contents of register q (normal mode) -- editing a register/recording
```

```vimtipsfortune
<ctrl-R>q --display contents of register q (insert mode)
```

```vimtipsfortune
"qdd --put changed contacts back into q -- you can now see recording contents, edit as required
```

```vimtipsfortune
v -- enter visual mode
```

```vimtipsfortune
V -- visual mode whole line
```

```vimtipsfortune
<C-V> -- enter VISUAL BLOCKWISE mode (remap on Windows to say C-Q *C*
```

```vimtipsfortune
gv -- reselect last visual area (ultra)
```

```vimtipsfortune
o -- navigate visual area
```

```vimtipsfortune
"*y or "+y -- yank visual area into paste buffer  [C]
```

```vimtipsfortune
V% -- visualise what you match
```

```vimtipsfortune
V}J -- Join Visual block (great)
```

```vimtipsfortune
V}gJ -- Join Visual block w/o adding spaces
```

```vimtipsfortune
] -- Highlight last insert
```

```vimtipsfortune
:%s/\%Vold/new/g -- Do a substitute on last visual area [N]
```

```vimtipsfortune
08l<c-v>10j2ld  (use Control Q on win32) [C] -- Delete 8th and 9th characters of 10 successive lines [C]
```

```vimtipsfortune
<C-V> then select "column(s)" with motion commands (win32 <C-Q>)
```

```vimtipsfortune
daW -- delete contiguous non whitespace -- text objects :h text-objects                                     [C]
```

```vimtipsfortune
di<   yi<  ci< -- Delete/Yank/Change HTML tag contents
```

```vimtipsfortune
da<   ya<  ca< -- Delete/Yank/Change whole HTML tag
```

```vimtipsfortune
dat   dit -- Delete HTML tag pair
```

```vimtipsfortune
diB   daB -- Empty a function {}
```

```vimtipsfortune
das -- delete a sentence
```

```vimtipsfortune
:imap <TAB> <C-N> -- set tab to complete [N] -- _vimrc essentials
```

```vimtipsfortune
:set incsearch -- jumps to search word as you type (annoying but excellent)
```

```vimtipsfortune
:set wildignore=*.o,*.obj,*.bak,*.exe -- tab complete now ignores these
```

```vimtipsfortune
:set shiftwidth=3 -- for shift/tabbing
```

```vimtipsfortune
:set vb t_vb=". -- set silent (no beep)
```

```vimtipsfortune
:set browsedir=buffer -- Maki GUI File Open use current directory
```

```vimtipsfortune
:nmap ,f :update<CR>:silent !start c:\progra~1\intern~1\iexplore.exe file://%:p<CR> -- launching Win IE
```

```vimtipsfortune
:nmap ,i :update<CR>: !start c:\progra~1\intern~1\iexplore.exe <cWORD><CR>
```

```vimtipsfortune
cmap ,r  :Nread ftp://209.51.134.122/public_html/index.html -- FTPing from VIM
```

```vimtipsfortune
cmap ,w  :Nwrite ftp://209.51.134.122/public_html/index.html
```

```vimtipsfortune
gvim ftp://www.somedomain.com/index.html # uses netrw.vim
```

```vimtipsfortune
"a5yy10j"A5yy
```

```vimtipsfortune
[I -- show lines matching word under cursor <cword> (super)
```

```vimtipsfortune
:'a,'b>> -- Conventional Shifting/Indenting
```

```vimtipsfortune
:vnoremap < <gv -- visual shifting (builtin-repeat)
```

```vimtipsfortune
:vnoremap > >gv
```

```vimtipsfortune
>i{ -- Block shifting (magic)
```

```vimtipsfortune
>a{ -- Block shifting (magic)
```

```vimtipsfortune
>% and <% -- Block shifting (magic)
```

```vimtipsfortune
== -- index current line same as line above [N]
```

```vimtipsfortune
:redir @* -- redirect commands to paste buffer -- Redirection & Paste register *
```

```vimtipsfortune
:redir END -- end redirect
```

```vimtipsfortune
:redir >> out.txt -- redirect to a file
```

```vimtipsfortune
"*yy -- yank curent line to paste -- Working with Paste buffer
```

```vimtipsfortune
"*p -- insert from paste buffer
```

```vimtipsfortune
:'a,'by* -- Yank range into paste -- yank to paste buffer (ex mode)
```

```vimtipsfortune
:%y* -- Yank whole buffer into paste
```

```vimtipsfortune
:.y* -- Yank Current line to paster -- filter non-printable characters from the paste buffer -- useful when pasting from some gui application
```

```vimtipsfortune
:nmap <leader>p :let @* = substitute(@*,'[^[:print:]]','','g')<cr>"*p
```

```vimtipsfortune
:set paste -- prevent vim from formatting pasted in text
```

```vimtipsfortune
gq} -- Format a paragraph -- Re-Formatting text
```

```vimtipsfortune
gqap -- Format a paragraph
```

```vimtipsfortune
ggVGgq -- Reformat entire file
```

```vimtipsfortune
Vgq -- current line
```

```vimtipsfortune
:s/.\{,69\};\s*\|.\{,69\}\s\+/&\r/g -- break lines at 70 chars, if possible after a ;
```

```vimtipsfortune
:argdo %s/foo/bar/e -- operate on all files in :args -- Operate command over multiple files
```

```vimtipsfortune
:bufdo %s/foo/bar/e -- operate on all files in :args -- Operate command over multiple files
```

```vimtipsfortune
:windo %s/foo/bar/e -- operate on all files in :args -- Operate command over multiple files
```

```vimtipsfortune
:argdo exe '%!sort'|w! -- include an external command
```

```vimtipsfortune
:bufdo exe "normal @q" | w -- perform a recording on open files
```

```vimtipsfortune
:silent bufdo !zip proj.zip %:p -- zip all current files
```

```vimtipsfortune
gvim -h -- help -- Command line tricks
```

```vimtipsfortune
ls | gvim - -- edit a stream!!
```

```vimtipsfortune
cat xx | gvim - -c "v/^\d\d\|^[3-9]/d -- -- filter a stream
```

```vimtipsfortune
gvim -o file1 file2 -- open into a horizontal split (file1 on top, file2 on bottom) [C]
```

```vimtipsfortune
gvim -O file1 file2 -- open into a vertical split (side by side,for comparing code) [N]
```

```vimtipsfortune
gvim.exe -c "/main" joe.c -- Open joe.c & jump to "main" -- execute one command after opening file
```

```vimtipsfortune
vim -c "%s/ABC/DEF/ge | update" file1.c -- execute multiple command on a single file
```

```vimtipsfortune
vim -c "argdo %s/ABC/DEF/ge | update" *.c -- execute multiple command on a group of files
```

```vimtipsfortune
vim -c "argdo /begin/+1,/end/-1g/^/d | update" *.c -- remove blocks of text from a series of files
```

```vimtipsfortune
vim -s "convert.vim" file.c -- Automate editing of a file (Ex commands in convert.vim)
```

```vimtipsfortune
gvim -u NONE -U NONE -N -- load VIM without .vimrc and plugins (clean VIM) e.g. for HUGE files
```

```vimtipsfortune
gvim -c 'normal ggdG"*p' c:/aaa/xp -- Access paste buffer contents (put in a script/batch file)
```

```vimtipsfortune
gvim -c 's/^/\=@*/|hardcopy!|q!' -- print paste contents to default printer
```

```vimtipsfortune
:!grep somestring *.php -- creates a list of all matching files [C] -- gvim's use of external grep (win32 or *nix)
```

```vimtipsfortune
:h grep -- use :cn(ext) :cp(rev) to navigate list
```

```vimtipsfortune
:vimgrep /keywords/ *.php -- Using vimgrep with copen
```

```vimtipsfortune
:copen
```

```vimtipsfortune
gvim -d file1 file2 -- vimdiff (compare differences) -- GVIM Difference Function (Brilliant)
```

```vimtipsfortune
dp -- "put" difference under cursor to other file
```

```vimtipsfortune
do -- "get" difference under cursor from other file
```

```vimtipsfortune
:1,2yank a | 7,8yank b -- complex diff parts of same file [N]
```

```vimtipsfortune
:tabedit | put a | vnew | put b
```

```vimtipsfortune
:windo diffthis 
```

```vimtipsfortune
In regular expressions you must backslash + (match 1 or more) -- Vim traps
```

```vimtipsfortune
In regular expressions you must backslash | (or)
```

```vimtipsfortune
In regular expressions you must backslash ( (group)
```

```vimtipsfortune
In regular expressions you must backslash { (count)
```

```vimtipsfortune
/fred\+/ -- matches fred/freddy but not free
```

```vimtipsfortune
/\(fred\)\{2,3}/ -- note what you have to break
```

```vimtipsfortune
/codes\(\n\|\s\)*where -- normal regexp -- \v or very magic (usually) reduces backslashing
```

```vimtipsfortune
/\vcodes(\n|\s)*where -- very magic
```

```vimtipsfortune
<C-R><C-W> -- pull word under the cursor into a command line or search -- pulling objects onto command/search line (SUPER)
```

```vimtipsfortune
<C-R><C-A> -- pull WORD under the cursor into a command line or search
```

```vimtipsfortune
<C-R>- -- pull small register (also insert mode)
```

```vimtipsfortune
<C-R>[0-9a-z] -- pull named registers (also insert mode)
```

```vimtipsfortune
<C-R>% -- pull file name (also #) (also insert mode)
```

```vimtipsfortune
<C-R>=somevar -- pull contents of a variable (eg :let sray="ray[0-9]")
```

```vimtipsfortune
:reg -- display contents of all registers -- List your Registers
```

```vimtipsfortune
:reg a -- display content of register a
```

```vimtipsfortune
:reg 12a -- display content of registers 1,2 & a [N]
```

```vimtipsfortune
"5p -- retrieve 5th "ring" 
```

```vimtipsfortune
"1p.... -- retrieve numeric registers one by one
```

```vimtipsfortune
:let @y='yy@"' -- pre-loading registers (put in .vimrc)
```

```vimtipsfortune
qqq -- empty register "q"
```

```vimtipsfortune
qaq -- empty register "a"
```

```vimtipsfortune
:reg .-/%:*" -- the seven special registers [N]
```

```vimtipsfortune
:reg 0 -- what you last yanked, not affected by a delete [N]
```

```vimtipsfortune
"_dd -- Delete to blackhole register "_ , don't affect any register [N]
```

```vimtipsfortune
:let @a=@_ -- clear register a -- manipulating registers
```

```vimtipsfortune
:let @a="" -- clear register a
```

```vimtipsfortune
:let @a=@" -- Save unnamed register [N]
```

```vimtipsfortune
:let @*=@a -- copy register a to paste buffer
```

```vimtipsfortune
:let @*=@: -- copy last command to paste buffer
```

```vimtipsfortune
:let @*=@/ -- copy last search to paste buffer
```

```vimtipsfortune
:let @*=@% -- copy current filename to paste buffer
```

```vimtipsfortune
:h quickref -- VIM Quick Reference Sheet (ultra) -- help for help (USE TAB)
```

```vimtipsfortune
:h tips -- Vim's own Tips Help
```

```vimtipsfortune
:h visual<C-D><tab> -- obtain  list of all visual help topics
```

 ```vimtipsfortune
-- Then use tab to step thru them
```

```vimtipsfortune
:h ctrl<C-D> -- list help of all control keys
```

```vimtipsfortune
:helpg uganda -- grep HELP Files use :cn, :cp to find next
```

```vimtipsfortune
:helpgrep edit.*director: grep help using regexp
```

```vimtipsfortune
:h :r -- help for :ex command
```

```vimtipsfortune
:h CTRL-R -- normal mode
```

```vimtipsfortune
:h /\r -- what's \r in a regexp (matches a <CR>)
```

```vimtipsfortune
:h \\zs -- double up backslash to find \zs in help
```

```vimtipsfortune
:h i_CTRL-R -- help for say <C-R> in insert mode
```

```vimtipsfortune
:h c_CTRL-R -- help for say <C-R> in command mode
```

```vimtipsfortune
:h v_CTRL-V -- visual mode
```

```vimtipsfortune
:h tutor -- VIM Tutor
```

```vimtipsfortune
<C-[>, <C-T> -- Move back & Forth in HELP History
```

```vimtipsfortune
gvim -h -- VIM Command Line Help
```

```vimtipsfortune
:cabbrev h tab h -- open help in a tab [N]
```

```vimtipsfortune
:scriptnames -- list all plugins, _vimrcs loaded (super) -- where was an option set
```

```vimtipsfortune
:verbose set history? -- reveals value of history and where set
```

```vimtipsfortune
:function -- list functions
```

```vimtipsfortune
:func SearchCompl -- List particular function
```

```vimtipsfortune
:helptags /vim/vim64/doc -- rebuild all *.txt help files in /doc -- making your own VIM help
```

```vimtipsfortune
:help add-local-help
```

```vimtipsfortune
:sav! $VIMRUNTIME/doc/vimtips.txt|:1,/^__BEGIN__/d|:/^__END__/,$d|:w!|:helptags $VIMRUNTIME/doc -- save this page as a VIM Help File [N]
```

```vimtipsfortune
map   <f9>   :w<CR>:!c:/php/php.exe %<CR> -- running file thru an external program (eg php)
```

```vimtipsfortune
map   <f2>   :w<CR>:!perl -c %<CR>
```

```vimtipsfortune
:new | r!perl # -- opens new buffer,read other buffer -- capturing output of current script in a separate buffer
```

```vimtipsfortune
:new! x.out | r!perl # -- same with named file
```

```vimtipsfortune
:new+read!ls
```

```vimtipsfortune
:new +put q|%!sort -- create a new buffer, paste a register "q" into it, then sort new buffer
```

```vimtipsfortune
:%s/$/\<C-V><C-M>&/g --  that's what you type -- Inserting DOS Carriage Returns
```

```vimtipsfortune
:%s/$/\<C-Q><C-M>&/g --  for Win32
```

```vimtipsfortune
:%s/$/\^M&/g --  what you'll see where ^M is ONE character
```

```vimtipsfortune
autocmd BufRead * silent! %s/[\r \t]\+$// -- automatically delete trailing Dos-returns,whitespace
```

```vimtipsfortune
autocmd BufEnter *.php :%s/[ \t\r]\+$//e
```

```vimtipsfortune
autocmd VimEnter c:/intranet/note011.txt normal! ggVGg?  -- perform an action on a particular file or file type
```

```vimtipsfortune
autocmd FileType *.pl exec('set fileformats=unix')
```

```vimtipsfortune
i<c-r>: -- Retrieving last command line command for copy & pasting into text
```

```vimtipsfortune
i<c-r>/ -- Retrieving last Search Command for copy & pasting into text
```

```vimtipsfortune
<C-X><C-F> :insert name of a file in current directory -- more completions
```

```vimtipsfortune
:'<,'>s/Emacs/Vim/g -- REMEMBER you dont type the '<.'>
```

```vimtipsfortune
gv -- Re-select the previous visual area (ULTRA)
```

```vimtipsfortune
:g/^/exec "s/^/".strpart(line(".")."    ", 0, 4) -- inserting line number into file
```

```vimtipsfortune
:%s/^/\=strpart(line(".")."     ", 0, 5)
```

```vimtipsfortune
:%s/^/\=line('.'). ' '
```

```vimtipsfortune
:set number -- show line numbers -- *numbering lines VIM way*
```

```vimtipsfortune
:map <F12> :set number!<CR> -- Show linenumbers flip-flop
```

```vimtipsfortune
:%s/^/\=strpart(line('.')."        ",0,&ts)
```

```vimtipsfortune
:'a,'b!perl -pne 'BEGIN{$a=223} substr($_,2,0)=$a++' -- numbering lines (need Perl on PC) starting from arbitrary number -- Produce a list of numbers -- Type in number on line say 223 in an empty file
```

```vimtipsfortune
nYP`n^Aq -- in recording q repeat with @q
```

```vimtipsfortune
:.,$g/^\d/exe "normal! \<c-a>" -- increment existing numbers to end of file (type <c-a> as 5 characters)
```

```vimtipsfortune
http://vim.sourceforge.net/tip_view.php?tip_id=150 -- advanced incrementing
```

```vimtipsfortune
let g:I=0
```

```vimtipsfortune
:let I=223 -- eg create list starting from 223 incrementing by 5 between markers a,b
```

```vimtipsfortune
:'a,'bs/^/\=INC(5)/
```

```vimtipsfortune
cab viminc :let I=223 \| 'a,'bs/$/\=INC(5)/ -- create a map for INC
```

```vimtipsfortune
o23<ESC>qqYp<C-A>q40@q -- *generate a list of numbers*  23-64
```

```vimtipsfortune
<C-U> -- delete all entered -- editing/moving within current insert (Really useful)
```

```vimtipsfortune
<C-W> -- delete last word
```

```vimtipsfortune
<HOME><END> -- beginning/end of line
```

```vimtipsfortune
<C-LEFTARROW><C-RIGHTARROW> -- jump one word backwards/forwards
```

```vimtipsfortune
<C-X><C-E>,<C-X><C-Y> -- scroll while staying put in insert
```

```vimtipsfortune
#encryption (use with care: DON'T FORGET your KEY)
```

```vimtipsfortune
:X -- you will be prompted for a key
```

```vimtipsfortune
:h :X
```

```vimtipsfortune
// vim:noai:ts=2:sw=4:readonly: -- modeline (make a file readonly etc) must be in first/last 5 lines
```

```vimtipsfortune
:h modeline -- vim:ft=html: -- says use HTML Syntax highlighting
```

```vimtipsfortune
amenu  Modeline.Insert\ a\ VIM\ modeline <Esc><Esc>ggOvim:ff=unix ts=4 ss=4<CR>vim60:fdm=marker<esc>gg -- Creating your own GUI Toolbar entry
```

```vimtipsfortune
map ,p :call SaveWord()
```

```vimtipsfortune
:g/^/ call Del()
```

```vimtipsfortune
:digraphs -- display table -- Digraphs (non alpha-numerics)
```

```vimtipsfortune
:h dig -- help
```

```vimtipsfortune
i<C-K>e' -- enters é
```

```vimtipsfortune
i<C-V>233 -- enters é (Unix)
```

```vimtipsfortune
i<C-Q>233 -- enters é (Win32)
```

```vimtipsfortune
ga -- View hex value of any character
```

```vimtipsfortune
#Deleting non-ascii characters (some invisible)
```

```vimtipsfortune
:%s/[\x00-\x1f\x80-\xff]/ /g -- type this as you see it
```

```vimtipsfortune
:%s/[<C-V>128-<C-V>255]//gi -- where you have to type the Control-V
```

```vimtipsfortune
:%s/[-ÿ]//gi -- Should see a black square & a dotted y
```

```vimtipsfortune
:%s/[<C-V>128-<C-V>255<C-V>01-<C-V>31]//gi -- All pesky non-asciis
```

```vimtipsfortune
:exec "norm /[\x00-\x1f\x80-\xff]/" -- same thing
```

```vimtipsfortune
#Pull a non-ascii character onto search bar yl/<C-R>"
```

```vimtipsfortune
/[^a-zA-Z0-9_[:space:][:punct:]] -- search for all non-ascii
```

```vimtipsfortune
:e main_<tab> -- tab completes -- All file completions grouped (for example main_c.c)
```

```vimtipsfortune
gf -- open file under cursor  (normal)
```

```vimtipsfortune
main_<C-X><C-F> -- include NAME of file in text (insert mode)
```

```vimtipsfortune
:%s/\<\(on\|off\)\>/\=strpart("offon", 3 * ("off" == submatch(0)), 3)/g
```

```vimtipsfortune
oremap <C-X> <Esc>`.``gvP``P -- swap two words
```

```vimtipsfortune
nmap <silent> gw    "_yiw:s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<cr><c-o><c-l> [N] -- Swap word with next word
```

```vimtipsfortune
:runtime! syntax/2html.vim -- convert txt to html -- Convert Text File to HTML
```

```vimtipsfortune
:h 2html
```

```vimtipsfortune
:grep some_keyword *.c -- get list of all c-files containing keyword -- VIM has internal grep
```

```vimtipsfortune
:cn -- go to next occurrence
```

```vimtipsfortune
:set syntax=perl -- Force Syntax coloring for a file that has no extension .pl
```

```vimtipsfortune
:set syntax off -- Remove syntax coloring (useful for all sorts of reasons)
```

```vimtipsfortune
:colorscheme blue -- change coloring scheme (any file in ~vim/vim??/colors)
```

```vimtipsfortune
:colorscheme morning -- good fallback colorscheme *N*
```

```vimtipsfortune
# vim:ft=html: -- Force HTML Syntax highlighting by using a modeline
```

```vimtipsfortune
au BufRead,BufNewFile */Content.IE?/* setfiletype html -- Force syntax automatically (for a file with non-standard extension)
```

```vimtipsfortune
:set noma (non modifiable) -- Prevents modifications
```

```vimtipsfortune
:set ro (Read Only) -- Protect a file from unintentional writes
```

```vimtipsfortune
gvim file1.c file2.c lib/lib.h lib/lib2.h -- load files for "session" -- Sessions (Open a set of files)
```

```vimtipsfortune
:mksession -- Make a Session file (default Session.vim)
```

```vimtipsfortune
:mksession MySession.vim -- Make a Session file named file [C]
```

```vimtipsfortune
gvim -S -- Reload all files (loads Session.vim) [C]
```

```vimtipsfortune
gvim -S MySession.vim -- Reload all files from named session [C]
```

```vimtipsfortune
#tags (jumping to subroutines/functions)
```

```vimtipsfortune
taglist.vim -- popular plugin
```

```vimtipsfortune
:Tlist -- display Tags (list of functions)
```

```vimtipsfortune
<C-]> -- jump to function under cursor
```

```vimtipsfortune
:let width = 20 -- columnise a csv file for display only as may crop wide columns
```

```vimtipsfortune
:let fill=' ' | while strlen(fill) < width | let fill=fill.fill | endwhile
```

```vimtipsfortune
:%s/\([^;]*\);\=/\=strpart(submatch(1).fill, 0, width)/ge
```

```vimtipsfortune
:%s/\s\+$//ge
```

```vimtipsfortune
command! -nargs=1 Csv :call CSVH(<args>)
```

```vimtipsfortune
:Csv 5 -- highlight fifth column -- call with
```

```vimtipsfortune
zf1G -- fold everything before this line [N]
```

```vimtipsfortune
zf} -- fold paragraph using motion -- folding : hide sections to allow easier comparisons
```

```vimtipsfortune
v}zf -- fold paragraph using visual
```

```vimtipsfortune
zf'a -- fold to mark
```

```vimtipsfortune
zo -- open fold
```

```vimtipsfortune
zc -- re-close fold
```

```vimtipsfortune
:help folding -- also visualise a section of code then type zf [N]
```

```vimtipsfortune
zfG -- fold everything after this line [N]
```

```vimtipsfortune
:set list -- displaying "non-asciis"
```

```vimtipsfortune
:h listchars
```

```vimtipsfortune
:norm qqy$jq -- How to paste "normal vim commands" w/o entering insert mode
```

```vimtipsfortune
:h filename-modifiers -- help -- manipulating file names
```

```vimtipsfortune
:w % -- write to current file name
```

```vimtipsfortune
:w %:r.cfm -- change file extention to .cfm
```

```vimtipsfortune
:!echo %:p -- full path & file name
```

```vimtipsfortune
:!echo %:p:h -- full path only
```

```vimtipsfortune
:!echo %:t -- filename only
```

```vimtipsfortune
:reg % -- display filename
```

```vimtipsfortune
<C-R>% -- insert filename (insert mode)
```

```vimtipsfortune
"%p -- insert filename (normal mode)
```

```vimtipsfortune
/<C-R>% -- Search for file name in text
```

```vimtipsfortune
"_d -- what you've ALWAYS wanted -- delete without destroying default buffer contents
```

```vimtipsfortune
"_dw -- eg delete word (use blackhole)
```

```vimtipsfortune
nnoremap <F2> :let @*=expand("%:p")<cr> :unix -- pull full path name into paste buffer for attachment to email etc
```

```vimtipsfortune
nnoremap <F2> :let @*=substitute(expand("%:p"), "/", "\\", "g")<cr> :win32
```

```vimtipsfortune
$ vim -- Simple Shell script to rename files w/o leaving vim
```

```vimtipsfortune
:r! ls *.c
```

```vimtipsfortune
:%s/\(.*\).c/mv & \1.bla
```

```vimtipsfortune
:w !sh
```

```vimtipsfortune
:q!
```

```vimtipsfortune
g<C-G>                                 # counts words -- count words/lines in a text file
```

```vimtipsfortune
:echo line("'b")-line("'a")            # count lines between markers a and b [N]
```

```vimtipsfortune
:'a,'bs/^//n                           # count lines between markers a and b
```

```vimtipsfortune
:'a,'bs/somestring//gn                 # count occurences of a string
```

```vimtipsfortune
:syn match DoubleSpace --  -- " example of setting your own highlighting
```

```vimtipsfortune
:hi def DoubleSpace guibg=#e0e0e0
```

```vimtipsfortune
imap ]  @@@<ESC>hhkyWjl?@@@<CR>P/@@@<CR>3s -- reproduce previous line word by word
```

```vimtipsfortune
nmap ] i@@@<ESC>hhkyWjl?@@@<CR>P/@@@<CR>3s
```

```vimtipsfortune
:autocmd bufenter *.tex map <F1> :!latex %<CR> -- Programming keys depending on file type
```

```vimtipsfortune
:autocmd bufenter *.tex map <F2> :!xdvi -hush %<.dvi&<CR>
```

```vimtipsfortune
:autocmd bufenter *.php :set iskeyword+=\$ -- allow yanking of php variables with their dollar [N]
```

```vimtipsfortune
:autocmd BufReadPre *.doc set ro -- reading Ms-Word documents, requires antiword (not docx)
```

```vimtipsfortune
:autocmd BufReadPre *.doc set hlsearch!
```

```vimtipsfortune
:autocmd BufReadPost *.doc %!antiword "%"
```

```vimtipsfortune
"act< --  Change Till < [N] -- store text that is to be changed or deleted in register a
```

```vimtipsfortune
vim -c ":%s%s*%Cyrnfr)fcbafbe[Oenz(Zbbyranne%|:%s)[[()])-)Ig|norm Vg?" -- *Just Another Vim Hacker JAVH*
```

```vimtipsfortune
zz to center the cursor vertically on your screen. Useful when you 250Gzz, for instance.
```

```vimtipsfortune
CTRL-w | and CTRL-W _ maximize your current split vertically and horizontally, respectively. CTRL-W = equalizes 'em.
```

```vimtipsfortune
%s/^\n// to delete all empty lines
```

```vimtipsfortune
:g/_pattern_/s/^/#/g will comment out lines containing _pattern_ (if '#' is your comment character/sequence)
```

```vimtipsfortune
vim -c [command] will launch vim and run a -- command at launch, e.g. "vim -c NERDTree."
```

```vimtipsfortune
CTRL-w s CTRL-w T will open current buffer in new tab
```

```vimtipsfortune
CTRL-w K will switch vertical split into horizontal, CTRL-w H will switch a horizontal into a vertical.
```

```vimtipsfortune
:w !sudo tee % will use sudo to write the open file (have you ever forgotten to `sudo vim /path/to/file`?)
```

```vimtipsfortune
K runs a prgrm to lookup the keyword under the cursor. If writing C, it runs man. In Ruby, it (should) run ri, Python (perhaps) pydoc.
```

```vimtipsfortune
Edit and encrypt a file: vim -x filename
```

```vimtipsfortune
:%s//joe/igc substitute your last search with joe.
```

```vimtipsfortune
/fred\_s*joe/ will search for fred AND joe with whitespace (including newline) in between.
```

```vimtipsfortune
From a command-line, vim scp://username@host//path/to/file to edit a remote file locally.
```

```vimtipsfortune
/fred|joe/ will search for either fred OR joe.
```

```vimtipsfortune
/.*fred&.*joe/ will search for fred AND joe, in any order.
```

```vimtipsfortune
/<fred>/ will search for fred, but not alfred or frederick.
```

```vimtipsfortune
/joe/e will search for joe and place the cursor at the end of the match.
```

```vimtipsfortune
/joe/e+1 will search for joe and place the cursor at the end of the match, plus on character.
```

```vimtipsfortune
/joe/s-2 will search for joe and place the cursor at the start of the match, minus two characters.
```

```vimtipsfortune
/joe/+3 will search for joe and place the cursor three lines below the match.
```

```vimtipsfortune
/joe.*fred.*bill/ will search for joe AND fred AND bill, in that order.
```

```vimtipsfortune
/begin\_.*end will search for begin AND end over multiple lines.
```

```vimtipsfortune
:s/\(.*\):\(.*\)/\2 -- \1/ will reverse fields separated by ':'
```

```vimtipsfortune
%s/<C-R>a/bar/g will place the contents of register 'a' in the search, and replace it with 'bar'.
```

```vimtipsfortune
Edit a command output in Vim as a file: $ command | vim -
```

```vimtipsfortune
ggVG= will auto-format the entire document
```

```vimtipsfortune
'0 opens the last modified file ('1 '2 '3 works too)
```

```vimtipsfortune
[I (big i) shows lines containing the word under the cursor
```

```vimtipsfortune
In insert mode do Ctrl+r=53+17<Enter>. This way you can do some calcs with vim.
```

```vimtipsfortune
"_d will delete the selection without adding it to the yanked stack (sending it to the black hole register).
```

```vimtipsfortune
Basic commands 'f' and 't' (like first and 'til) are very powerful. See :help t or :help f.
```

```vimtipsfortune
:40,50m30 will move lines 40 through 50 to line 30. Most visual mode commands can be used with line numbers.
```

```vimtipsfortune
To search for a URL without backslashing, search backwards! Example: ?http://somestuff.com
```

```vimtipsfortune
:%s/~/sue/igc substitute your last replacement string with 'sue'.
```

```vimtipsfortune
g; will cycle through your recent changes (or g, to go in reverse).
```

```vimtipsfortune
:%s/^\n\{3}// will delete a block of 3 empty lines.
```

```vimtipsfortune
:%s/^\n\+/\r/ will compress multiple empty lines into one.
```

```vimtipsfortune
:%s#<[^>]\+>##g will remove HTML tags, leaving the text. (non-greedy)
```

```vimtipsfortune
:%s#.*(hours).*#1# will delete everything on a line except for the string 'hours'.
```

```vimtipsfortune
"2p will put the second to last thing yanked, "3p will put the third to last, etc.
```

```vimtipsfortune
:wa will save all buffers. :xa will save all buffers and exit Vim.
```

```vimtipsfortune
After performing an undo, you can navigate through the changes using g- and g+. Also, try :undolist to list the changes.
```

```vimtipsfortune
You probably know that 'u' is undo. Do you know that Ctrl-R is redo?
```

```vimtipsfortune
ci{ â change text inside {} block. Also see di{, yi{, ci( etc.
```

```vimtipsfortune
:set autochdir instead of :lcd %:p:h in your vimrc to change directories upon opening a file.
```

```vimtipsfortune
:read [filename] will insert the contents of [filename] at the current cursor position 
```

```vimtipsfortune
to use gvim to edit your git messages set git's core editor as follows:
```

```vimtipsfortune
:set foldmethod=syntax to make editing long files of code much easier.  zo to open a fold.  zc to close it.  See more
```

```vimtipsfortune
:%s/\ r//g to remove all those nasty ^M from a file, or :%s/\ r$//g for only at the end of a line.
```

```vimtipsfortune
Ctrl-a, Ctrl-x will increment and decrement, respectively, the number under the cursor.
```

```vimtipsfortune
You can use the environment variable 'SHLVL' to check if you are within a vim subshell or not.
```
