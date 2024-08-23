" patch for parsec

call cpatch#remove_background('SpecialKey')
call cpatch#remove_background('LineNr')
call cpatch#remove_background('SignColumn')

hi! SpecialKey term=bold ctermfg=238 guifg=#444444


