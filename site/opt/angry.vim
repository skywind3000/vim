" Author:  Bjorn Winckler
" Version: 0.1
" License: (c) 2012 Bjorn Winckler.  Licensed under the same terms as Vim.
"
" Summary:
"
" Text objects for function arguments ('arg' means 'angry' in Swedish) and
" other items surrounded by brackets and separated by commas.
"
" TODO:
"
" - Growing selection in visual mode does not work
" - Comments are not handled properly (difficult to accomodate all styles,
"   e.g. comment after argument, comment on line above argument, ...)
" - Support empty object (e.g. ',,' and ',/* comment */,')

if exists("g:loaded_angry") || &cp || v:version < 700 | finish | endif
let g:loaded_angry = 1

"
" Map to text objects aa (An Argument) and ia (Inner Argument) unless
" disabled.
"
" The objects aA and iA are similar to aa and ia, except aA and iA match at
" closing brackets, whereas aa and ia match at opening brackets and commas.
" Generally, the lowercase versions match to the right and the uppercase
" versions match to the left of the cursor.
"
if !exists("g:angry_disable_maps")
  vmap <silent> aa <Plug>AngryOuterPrefix
  omap <silent> aa <Plug>AngryOuterPrefix
  vmap <silent> ia <Plug>AngryInnerPrefix
  omap <silent> ia <Plug>AngryInnerPrefix

  vmap <silent> aA <Plug>AngryOuterSuffix
  omap <silent> aA <Plug>AngryOuterSuffix
  vmap <silent> iA <Plug>AngryInnerSuffix
  omap <silent> iA <Plug>AngryInnerSuffix
endif

"
" Specify which separator to use.
"
" TODO: This should probably be determined on a per-buffer (or filetype) basis.
"
if !exists('g:angry_separator')
  let g:angry_separator = ','
endif


vnoremap <silent> <script> <Plug>AngryOuterPrefix :<C-U>call
      \ <SID>List(g:angry_separator, 1, 1, v:count1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryOuterSuffix :<C-U>call
      \ <SID>List(g:angry_separator, 0, 1, v:count1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryInnerPrefix :<C-U>call
      \ <SID>List(g:angry_separator, 1, 0, v:count1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryInnerSuffix :<C-U>call
      \ <SID>List(g:angry_separator, 0, 0, v:count1, visualmode())<CR>

onoremap <silent> <script> <Plug>AngryOuterPrefix :call
      \ <SID>List(g:angry_separator, 1, 1, v:count1)<CR>
onoremap <silent> <script> <Plug>AngryOuterSuffix :call
      \ <SID>List(g:angry_separator, 0, 1, v:count1)<CR>
onoremap <silent> <script> <Plug>AngryInnerPrefix :call
      \ <SID>List(g:angry_separator, 1, 0, v:count1)<CR>
onoremap <silent> <script> <Plug>AngryInnerSuffix :call
      \ <SID>List(g:angry_separator, 0, 0, v:count1)<CR>


"
" Select item in a list.
"
" The list is enclosed by brackets (i.e. '()', '[]', or '{}').  Items are
" separated by a:sep (e.g. ',').
"
" If a:prefix is set, then outer selections include the leftmost separator but
" not the rightmost, and vice versa if a:prefix is not set.
"
" If a:outer is set an outer selection is made (which includes separators).
" If a:outer is not set an inner selection is made (which does not include
" separators on the boundary).  Outer selections are useful for deleting
" items, inner selection are useful for changing items.
"
function! s:List(sep, prefix, outer, times, ...)
  let lbracket = '[[({]'
  let rbracket = '[])}]'
  let save_mb = getpos("'b")
  let save_me = getpos("'e")
  let save_unnamed = @"
  let save_ic = &ic
  let &ic = 0

  try
    " Backward search for separator or unmatched left bracket.
    let flags = a:prefix ? 'bcW' : 'bW'
    if searchpair(lbracket, a:sep, rbracket, flags,
          \ 's:IsCursorOnStringOrComment()') <= 0
      return
    endif
    exe "normal! ylmb"
    let first = @"

    " Forward search for separator or unmatched right bracket as many times as
    " specified by the command count.
    if searchpair(lbracket, a:sep, rbracket, 'W',
          \ 's:IsCursorOnStringOrComment()') <= 0
      return
    endif
    exe "normal! yl"
    let times = a:times - 1
    while times > 0 && @" =~ a:sep && searchpair(lbracket, a:sep, rbracket,
          \ 'W', 's:IsCursorOnStringOrComment()') > 0
      let times -= 1
      exe "normal! yl"
    endwhile
    let last = @"

    " TODO: The below code is incorrect if the selection is too small.
    "
    " NOTE: The calls to searchpair() with pattern '\%0l' is used only for its
    " 'skip' argument that is employed to search outside comments (the '\%0l'
    " pattern never matches).
    let cmd = "v`e"
    if !a:outer
      call search('\S', 'bW')
      exe "keepjumps normal! me`b"
      call search('\S', 'W')
    elseif a:prefix
      if a:sep =~ first && a:sep =~ last
        " Separators on both sides
        call searchpair('\S', '', '\%0l', 'bW', 's:IsCursorOnComment()')
        exe "keepjumps normal! me`b"
        call searchpair('\S', '', '\%0l', 'bW', 's:IsCursorOnComment()')
        let cmd .= "o\<Space>o"
      elseif a:sep =~ first
        " Separator on the left, bracket on the right
        call searchpair('\S', '', '\%0l', 'bW', 's:IsCursorOnComment()')
        exe "keepjumps normal! me`b"
        call searchpair('\S', '', '\%0l', 'bW', 's:IsCursorOnComment()')
        let cmd .= "o\<Space>o"
      elseif a:sep =~ last
        " Bracket on the left, separator on the right
        call search('\S', 'W')
        exe "keepjumps normal! me`b"
        call search('\S', 'W')
        let cmd .= "\<C-H>"
      else
        " Brackets on both sides
        exe "keepjumps normal! me`b"
        let cmd .= "o\<Space>o\<C-H>"
      endif
    else  " !a:prefix
      if a:sep =~ first && a:sep =~ last
        " Separators on both sides
        call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnComment()')
        exe "keepjumps normal! me`b"
        call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnComment()')
        let cmd .= "\<C-H>"
      elseif a:sep =~ first
        " Separator on the left, bracket on the right
        call search('\S', 'bW')
        exe "keepjumps normal! me`b"
        call search('\S', 'bW')
        let cmd .= "o\<Space>o"
      elseif a:sep =~ last
        " Bracket on the left, separator on the right
        call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnComment()')
        exe "keepjumps normal! me`b"
        call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnComment()')
        let cmd .= "\<C-H>"
      else
        " Brackets on both sides
        exe "keepjumps normal! me`b"
        let cmd .= "o\<Space>o\<C-H>"
      endif
    endif

    if &sel == "exclusive"
      " The last character is not included in the selection when 'sel' is
      " exclusive so extend selection by one character on the right to
      " compensate.  Note that <Space> can go to next line if the cursor is on
      " the end of line, whereas 'l' can't.
      let cmd .= "\<Space>"
    endif

    exe "keepjumps normal! " . cmd
  finally
    call setpos("'b", save_mb)
    call setpos("'e", save_me)
    let @" = save_unnamed
    let &ic = save_ic
  endtry
endfunction

function! s:IsCursorOnComment()
   return synIDattr(synID(line("."), col("."), 0), "name") =~? "comment"
endfunction

function! s:IsCursorOnStringOrComment()
   let syn = synIDattr(synID(line("."), col("."), 0), "name")
   return syn =~? "string" || syn =~? "comment"
endfunction

