tabnew

let colors = []
call colorexp#colors#init()
for name in colorexp#colors#list_names()
	if name =~ '^Coc'
		let t = colorexp#colors#real_highlight(name, 1)
		let colors += [t]
	endif
endfor

call append(0, colors)
set nomodified


