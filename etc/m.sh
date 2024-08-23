#! /bin/bash


# m +foo  - add a new bookmark for your current working directory
# m -foo  - delete a bookmark
# m foo   - cd to the given bookmark directory
# m /bar  - search bookmarks matching "bar"
# m       - print a list of all bookmarks
function cd_mark() {
	MARKPATH="${MARKPATH:-$HOME/.local/share/marks}"
	[ -d "$MARKPATH" ] || mkdir -p -m 700 "$MARKPATH" 2> /dev/null
	case "$1" in
		+*)            # m +foo  - add new bookmark for $PWD
			ln -snf "$(pwd)" "$MARKPATH/${1:1}" 
			;;
		-*)            # m -foo  - delete a bookmark named "foo"
			rm -i "$MARKPATH/${1:1}" 
			;;
		/*)            # m /bar  - search bookmarks matching "bar"
			find "$MARKPATH" -type l -name "*${1:1}*" | \
				awk -F "/" '{print $NF}' | MARKPATH="$MARKPATH" xargs -I'{}'\
				sh -c 'echo "{} ->" $(readlink "$MARKPATH/{}")'
			;;
		"")            # m       - list all bookmarks
			command ls -1 "$MARKPATH/" | MARKPATH="$MARKPATH" xargs -I'{}' \
				sh -c 'echo "{} ->" $(readlink "$MARKPATH/{}")'
			;;
		*)             # m foo   - cd to the bookmark directory
			local dest="$(readlink "$MARKPATH/$1" 2> /dev/null)"
			[ -d "$dest" ] && cd "$dest" || echo "No such mark: $1"
			;;
	esac
}

# by default, alias cd_mark to m
alias ${MARKCMD:-m}='cd_mark'

if [ -n "$BASH_VERSION" ]; then
	function _cdmark_complete() {
		local MARKPATH="${MARKPATH:-$HOME/.local/share/marks}"
		local curword="${COMP_WORDS[COMP_CWORD]}"
		if [[ "$curword" == "-"* ]]; then
			COMPREPLY=($(find "$MARKPATH" -type l -name "${curword:1}*" \
				2> /dev/null | awk -F "/" '{print "-"$NF}'))
		else
			COMPREPLY=($(find "$MARKPATH" -type l -name "${curword}*" \
				2> /dev/null | awk -F "/" '{print $NF}'))
		fi
	}
	complete -F _cdmark_complete ${MARKCMD:-m}
elif [ -n "$ZSH_VERSION" ]; then
	function _cdmark_complete() {
		local MARKPATH="${MARKPATH:-$HOME/.local/share/marks}"
		if [[ "${1}${2}" == "-"* ]]; then
			reply=($(command ls -1 "$MARKPATH" 2> /dev/null | \
				awk '{print "-"$0}'))
		else
			reply=($(command ls -1 "$MARKPATH" 2> /dev/null))
		fi
	}
	compctl -K _cdmark_complete cd_mark
fi




