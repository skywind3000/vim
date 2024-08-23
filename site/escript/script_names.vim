redir => x
silent scriptnames
redir END
tabnew
let @0=x
exec 'normal "0Pggdd'
setlocal nomodified

