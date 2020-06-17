#
# Uses the editorconfig CLI to get the given file's configured preferred indentation settings.
# If it works, it sets $_indent_style to "tab" or "space", and/or $_indent_size to a number.
#
# Copyright (c) 2020 Jason Jackson. MIT License.
#

function use-editorconfig() {
	local file_path="$1"

	export _indent_style=""  # Return value, "tab" or "space"
	export _indent_size=""   # Return value, number of spaces

	[[ -r $file_path && -f $file_path ]] || return 0

	if [[ $file_path != /* ]]; then
		[[ $PWD == "/" ]] && file_path="/$file_path" || file_path="$PWD/$file_path"
	fi

	local line indent_style="" indent_size="" tab_width=""

	while IFS="" read -r line; do
		line="${line//[$'\t ']/}"

		if [[ $line == "indent_style="* ]]; then
			indent_style="${line//*=/}"
		elif [[ $line == "indent_size="* ]]; then
			indent_size="${line//*=/}"
		elif [[ $line == "tab_width="* ]]; then
			tab_width="${line//*=/}"
		fi
	done < <( editorconfig "$file_path" 2> /dev/null )

	if [[ $indent_style == "space" ]]; then
		_indent_style="space"

		# If indent_size is "tab" in .editorconfig, it'll be resolved by editorconfig to a number,
		# if tab_width is set to one - so there's no point in checking tab_width here
		if [[ $indent_size =~ ^[0-9]+$ ]]; then
			_indent_size=$indent_size
		fi
	else
		[[ $indent_style == "tab" ]] && _indent_style="tab"

		if [[ $tab_width =~ ^[0-9]+$ ]]; then
			_indent_size=$tab_width
		elif [[ $indent_size =~ ^[0-9]+$ ]]; then
			# Fall back to indent_size if tab_width isn't present/valid
			_indent_size=$indent_size
		fi
	fi
}
