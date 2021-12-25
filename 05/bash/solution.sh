#!/usr/bin/env bash
#
# Determine at how many points lines intersect

# Show Help/Usage
show_help() {
	cat << EOF
Determine at how many points lines intersect

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-d, --diagonal	Consider diagonal lines
EOF
}

getWidth() {
	sed 's/ -> /,/' "${*}" | \
		awk --field-separator="," '{print $1 + 1 "\n" $3 + 1}' | \
		sort --numeric-sort --reverse | \
		head -1
}

getHeight() {
	sed 's/ -> /,/' "${*}" | \
		awk --field-separator="," '{print $2 + 1 "\n" $4 + 1}' | \
		sort --numeric-sort --reverse | \
		head -1
}

abs() {
	printf '%s\n' "${1/-/}"
}

calculate() {
	local -a diagram
	local width height count i x y x1 x2 y1 y2

	width="$(getWidth "${*}")"
	height="$(getHeight "${*}")"

	for ((i = 0; i < width * height; i++)); do
		((diagram[i] = 0))
	done

	while read -r x1 y1 x2 y2; do
		if ((x1 == x2)) && ((y1 == y2)); then
			((diagram[y1 * width + x1]++))
		elif ((x1 == x2)); then
			if ((y1 > y2)); then
				for ((i = y2; i <= y1; i++)); do
					((diagram[i * width + x1]++))
				done
			else
				for ((i = y1; i <= y2; i++)); do
					((diagram[i * width + x1]++))
				done
			fi
		elif ((y1 == y2)); then
			if ((x1 > x2)); then
				for ((i = x2; i <= x1; i++)); do
					((diagram[y1 * width + i]++))
				done
			else
				for ((i = x1; i <= x2; i++)); do
					((diagram[y1 * width + i]++))
				done
			fi
		elif [ -n "${diagonal}" ] && (($(abs "$((x1 - x2))") == $(abs "$((y1 - y2))"))); then
			if ((x1 > x2)); then
				if ((y1 > y2)); then
					for ((x = x1, y = y1; x >= x2; x--, y--)); do
						((diagram[y * width + x]++))
					done
				else
					for ((x = x1, y = y1; x >= x2; x--, y++)); do
						((diagram[y * width + x]++))
					done
				fi
			elif ((y1 > y2)); then
				for ((x = x1, y = y1; y >= y2; x++, y--)); do
					((diagram[y * width + x]++))
				done
			else
				for ((x = x1, y = y1; y <= y2; x++, y++)); do
					((diagram[y * width + x]++))
				done
			fi
		fi
	done <<< "$(sed 's/,/ /g;s/ -> / /' "${*}")"

	count="0"
	for i in "${diagram[@]}"; do
		((i >= 2 && count++))
	done
	printf '%s\n' "Overlaps: ${count}"
}

main() {
	local opts diagonal

	opts="$(getopt --options hd --longoptions help,diagonal --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
			-d | --diagonal )	diagonal="1";;
			-- )				shift; break;;
			* )					break;;
		esac
		shift
	done

	if [ -z "${*}" ]; then
		printf '%s\n' "No input file specified" >&2
		return 1
	fi

	if ! [ -s "${*}" ]; then
		printf '%s\n' "Input file contains no data" >&2
		return 1
	fi

	if grep --quiet '[^0-9,> \r\n-]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	calculate "${*}"
}

main "${@}"
