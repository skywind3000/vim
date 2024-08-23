let x = luaeval('package.path')

tabnew
for n in split(x, ';')
	call append('$', [n])
endfor


exec "normal ggdd"
set nomodified

