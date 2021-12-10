let opts = {}
let opts.w = 50
let opts.h = 10
let opts.x = 1
let opts.y = 1
let opts.title = ' Hello, World '
let opts.border = 'rounded'
let opts.padding = [0, 1, 0, 1]
let text = ['0123456789', '67890']

let win = quickui#window#new()
call win.open(text, opts)
" call win.set_text(text)
" call win.execute('setl number')


redraw

echo win.opts

call getchar()

call win.show(0)
redraw
call getchar()

call win.set_line(4, 'Hello, Vim World !!')
call win.move(50, 10)
call win.show(1)
call win.resize(30, 7)
call win.center()
redraw
call getchar()

call win.close()



