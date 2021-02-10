# login shell will execute this

if [ -n "$BASH_VERSION" ]; then
	# include .bashrc if it exists
	if [ -f "$HOME/.bashrc" ]; then
		. "$HOME/.bashrc"
	fi
else
	if [ -f "$HOME/.local/etc/init.sh" ]; then
		. "$HOME/.local/etc/init.sh"
	fi
fi

if [ -f "$HOME/.local/etc/login.sh" ]; then
	. "$HOME/.local/etc/login.sh"
fi


