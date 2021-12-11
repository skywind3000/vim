let choices = "&OK\nDis&card\n&Quit"
let question = "Make your choice:"

if 0
	let hwnd = quickui#confirm#init(question, choices, -1, 'Confirm')

	for text in hwnd.content
		echo text 
	endfor
endif

let hwnd = quickui#confirm#open(question, choices, 0, 'Confirm')
let off = hwnd.padding
for item in hwnd.items
	" echo [off + item.start, off + item.endup]
	" echo '[' . item.text . ']'
endfor

