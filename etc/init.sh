# init script for interactive shells
# vim: set ft=sh :

# prevent loading twice
if [ -z "$_INIT_SH_LOADED" ]; then
	_INIT_SH_LOADED=1
else
	return
fi

# skip if in non-interactive mode
case "$-" in
	*i*) ;;
	*) return
esac

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ]; then
	export PATH="$HOME/.local/bin:$PATH"
fi

# execute local init script if it exists
if [ -f "$HOME/.local/etc/config.sh" ]; then
	. "$HOME/.local/etc/config.sh"
fi

# execute post script if it exists
if [ -f "$HOME/.local/etc/local.sh" ]; then
	. "$HOME/.local/etc/local.sh"
fi

# remove duplicate path
if [ -n "$PATH" ]; then
	old_PATH=$PATH:; PATH=
	while [ -n "$old_PATH" ]; do
		x=${old_PATH%%:*}        # the first remaining entry
		case $PATH: in
			*:"$x":*) ;;         # already there
			*) PATH=$PATH:$x;;   # not there yet
		esac
		old_PATH=${old_PATH#*:}
	done
	PATH=${PATH#:}
	unset old_PATH x
fi

export PATH

# check if bash or zsh
if [ -n "$BASH_VERSION" ] || [ -n "$ZSH_VERSION" ]; then

	# run script for interactive mode of bash/zsh
	if [[ $- == *i* ]] && [ -z "$INIT_SH_NOFUN" ]; then
		if [ -f "$HOME/.local/etc/function.sh" ]; then
			. "$HOME/.local/etc/function.sh"
		fi
	fi
fi

# check if login shell
if [ -n "$BASH_VERSION" ]; then
	if shopt -q login_shell; then
		if [ -f "$HOME/.local/etc/login.sh" ] && [ -z "$INIT_SH_NOLOG" ]; then
			. "$HOME/.local/etc/login.sh"
		fi
	fi
elif [ -n "$ZSH_VERSION" ]; then
	if [[ -o login ]]; then
		if [ -f "$HOME/.local/etc/login.sh" ] && [ -z "$INIT_SH_NOLOG" ]; then
			. "$HOME/.local/etc/login.sh"
		fi
	fi
fi



