#
# Detects the given file's predominant indentation.
# Set $_indent_style to "tab", "space", or an empty string if anything goes sideways.
# If the file appears to favor space indentation, it'll also set $_indent_size to a number
# representing the dominant indentation size. 
#
# This only works on ASCII and UTF-8 text, and has only been tested on macOS's bash v3.2.57.
#
# Based on https://medium.com/firefox-developer-tools/detecting-code-indentation-eff3ed0fb56b
# and https://github.com/sindresorhus/detect-indent.
#
# Copyright (c) 2020 Jason Jackson. MIT License.
#

function detect-indent() {
	local file_path="$1"

	export _indent_style=""  # Return value, "tab" or "space"
	export _indent_size=""   # Return value, number of spaces (iff _indent_style is "space")

	[[ -r $file_path && -f $file_path ]] || return

	local spaced_count=0 tabbed_count=0  # Counts of lines indented with spaces/tabs

	declare -a space_counts=()    # Relative space-based indents -> count of times seen
	local space_counts_max_key=0  # Biggest key in $space_counts (so we can iterate)

	# If we find an equal number of blocks with different relative indents,
	# we'll use the total number of lines in the blocks as a tie-breaker
	declare -a tiebreakers=()

	declare -a lines=()
	local max_chars=20000  # Don't bog down reading big files, the first 20 KB should be plenty
	IFS=$'\n' read -a lines -n $max_chars -d '' -r < "$file_path" || true  # Drops empty lines

	local line last_indent_type="" last_indent_size=0 last_rel_indent_size=0

	# Read the file line-by-line, looking for lines indented further than the line above them
	for line in "${lines[@]}"; do
		local line_indent="${line//[^$'\t ']*/}"
		[[ "$line" == "$line_indent" ]] && continue  # Skip lines that're all whitespace

		if [[ -z $line_indent ]]; then
			last_indent_type=""
			last_indent_size=0
			last_rel_indent_size=0

		elif [[ $line_indent == *$'\t'* ]]; then
			last_indent_type="tab"
			(( tabbed_count++ ))

		else
			local indent_size=${#line_indent}

			if [[ $last_indent_type != "tab" ]]; then
				local rel_indent_size=$(( indent_size - last_indent_size ))

				if (( 2 <= rel_indent_size && rel_indent_size <= 8 )); then
					(( space_counts[rel_indent_size]++ ))
					(( rel_indent_size <= space_counts_max_key )) || space_counts_max_key=$rel_indent_size
					(( tiebreakers[rel_indent_size]++ ))
					last_rel_indent_size=$rel_indent_size

				elif (( rel_indent_size == 0 )); then
					(( tiebreakers[last_rel_indent_size]++ ))
				else
					last_rel_indent_size=0
				fi
			fi

			last_indent_type="spaces"
			last_indent_size=$indent_size
			(( spaced_count++ ))
		fi
	done

	# Set $_indent_style and $_indent_size based on what we found in the file
	if (( spaced_count < tabbed_count )); then
		_indent_style="tab"
	else
		local spaces winning_count=0 winning_tiebreaker=0

		for (( spaces=2; spaces <= space_counts_max_key; spaces++ )); do
			local count="${space_counts[$spaces]}"
			[[ -n $count ]] || continue

			if (( count > winning_count ||
				(count == winning_count && tiebreakers[spaces] > winning_tiebreaker) ))
			then
				_indent_style="space"
				_indent_size=$spaces
				winning_count=$count
				winning_tiebreaker=${tiebreakers[$spaces]}
			fi
		done
	fi
}
