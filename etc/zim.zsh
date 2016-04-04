# zim framework
ZDOTDIR="$HOME/.local/zsh"
ZIMDIR="$ZDOTDIR/.zim"

if [ ! -d "$ZIMDIR" ]; then
	[ ! -d "$HOME/.local" ] && mkdir -p "$HOME/.local" 2> /dev/null
	[ ! -d "$HOME/.local/bin" ] && mkdir -p "$HOME/.local/bin" 2> /dev/null
	[ ! -d "$HOME/.local/zsh" ] && mkdir -p "$HOME/.local/zsh" 2> /dev/null
	git clone --recursive https://github.com/zimfw/zimfw.git "$ZIMDIR"

	setopt EXTENDED_GLOB
	for template_file ( ${ZDOTDIR:-${HOME}}/.zim/templates/* ); do
		user_file="${ZDOTDIR:-${HOME}}/.${template_file:t}"
		touch ${user_file}
		( print -rn "$(<${template_file})$(<${user_file})" >! ${user_file} ) 2>/dev/null
	done
fi


export PS1="%n@%m:%~%# "

# syntax color definition
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

typeset -A ZSH_HIGHLIGHT_STYLES

# ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
# ZSH_HIGHLIGHT_STYLES[alias]='fg=magenta,bold'

ZSH_HIGHLIGHT_STYLES[default]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=009
ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=009,standout
ZSH_HIGHLIGHT_STYLES[alias]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[builtin]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[function]=fg=cyan,bold
ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
ZSH_HIGHLIGHT_STYLES[precommand]=fg=white,underline
ZSH_HIGHLIGHT_STYLES[commandseparator]=none
ZSH_HIGHLIGHT_STYLES[hashed-command]=fg=009
ZSH_HIGHLIGHT_STYLES[path]=fg=214,underline
ZSH_HIGHLIGHT_STYLES[globbing]=fg=063
ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=white,underline
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=none
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=none
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=063
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=063
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=009
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=009
ZSH_HIGHLIGHT_STYLES[assign]=none


[ -f "$HOME/.local/etc/init.sh" ] && source "$HOME/.local/etc/init.sh"

source "$HOME/.local/zsh/.zshrc"

if [[ -o login ]]; then
	source "$HOME/.local/zsh/.zlogin"
fi


# export PS1="%n@%m:%~%# "

