let s:windows = has('win32') || has('win64') || has('win95') || has('win16')

tabnew
let p = split($PATH, s:windows? ';' : ':')
call sort(p)

call append('$', p)

