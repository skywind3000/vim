let s:windows = has('win32') || has('win16') || has('win95') || has('win64')
let g:asclib#common#windows = s:windows
let g:asclib#common#unix = (s:windows == 0)? 1 : 0


