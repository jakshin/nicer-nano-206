# Bash completions for nano v2.0.6
# (Also for nano206++.sh's '--tabs' option)

function _nano() {
	local i
	for (( i=COMP_CWORD-1; i >= 0; i-- )); do
		# We only provide completions for options, so just bail if "--" was already passed
		[[ ${COMP_WORDS[$i]} == "--" ]] && return
	done

	local current_word="${COMP_WORDS[COMP_CWORD]}"
	if [[ $current_word == -* ]]; then
		# Start with options supported by nano v2.0.6
		local opts='--autoindent --backup --backupdir= --boldtext --const --cut --fill= --help
								--historylog --ignorercfiles --morespace --mouse --multibuffer --noconvert
								--nofollow --nohelp --nonewlines --noread --nowrap --operatingdir= --preserve
								--quickblank --quotestr= --rebinddelete --rebindkeypad --restricted --smarthome
								--smooth --speller= --suspend --syntax= --tabsize= --tabstospaces --tempfile
								--version --view --wordbounds -A -B -c -C -d -D -E -F -h -H -i -I -k -K -l -L
								-m -n -N -o -O -p -Q -r -R -s -S -t -T -U -v -V -w -W -x -Y -z'

		# If "nano" is actually nano206++.sh, via alias/function/symlink, add a "--tabs" option
		if [[ "$(type nano)" == *"nano206++"* ]]; then
			opts+=' --tabs'
		else
			local nano_cmd="$(type -p nano)"
			if [[ -L $nano_cmd && "$(readlink "$nano_cmd")" == *"nano206++.sh"* ]]; then
				opts+=' --tabs'
			fi
		fi

		COMPREPLY=( $(compgen -W "$opts" -- "$current_word") )
	fi
}

complete -F _nano -o bashdefault -o default nano
