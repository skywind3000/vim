
messages clear
let textlist = [
			\ ["&New File\tCtrl+n", 'echo "new file"'],
			\ ["&Open File\tCtrl+o", 'echo "open file"'],
			\ ["&Close", 'echo 1234', 'help 1'],
			\ "--",
			\ "&Save\tCtrl+s",
			\ "Save &As",
			\ "Save All",
			\ "--",
			\ "&User Menu\tF9",
			\ "&Dos Shell",
			\ "~&Time %{&undolevels? '+':'-'}",
			\ ["S&plit", 'help 1', '', 'vim2'],
			\ "--",
			\ ["&More\tF3", [ 
			\   ["Hello &World\tF4", 'echo 123'],
			\   ["Kiss &Me\tF5", 'echo 456'],
			\ ] ],
			\ "E&xit\tAlt+x",
			\ "&Help",
			\ ]
let opts = {}
let opts.index = 2
let opts.border = 1
let opts.direct = 1
call quickui#context#open_nested(textlist, opts)

