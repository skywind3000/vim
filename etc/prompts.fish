# Defined in /usr/share/fish/functions/fish_prompt.fish @ line 5
function fish_prompt --description 'Write out the prompt'
	set -l color_cwd
	set -l suffix
	switch "$USER"
	case root toor
		if set -q fish_color_cwd_root
			set color_cwd $fish_color_cwd_root
		else
			set color_cwd $fish_color_cwd
		end
		set suffix '#'
	case '*'
		set color_cwd $fish_color_cwd
		set suffix '>'
	end
	echo -n -s "$USER" @ (prompt_hostname) ' ' (set_color $color_cwd) (prompt_pwd) (set_color normal) "$suffix "
end

# Defined in /home/skywind/.local/share/omf/themes/default/fish_right_prompt.fish @ line 1
function fish_right_prompt
	set -l st $status
	if [ $st != 0 ];
		echo (set_color red) $st(set_color normal) " "
	end
	set_color $fish_color_autosuggestion 2> /dev/null; or set_color 555
	date "+%H:%M:%S"
	set_color normal
end


