#!/usr/bin/env bash
#
# Get the number of lanternfish

# Show Help/Usage
show_help() {
	cat << EOF
Get the number of lanternfish

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help	Show this help message
	-d, --days INT	Specify the number of days to run the model
EOF
}

shiftArray() {
	shift
	printf '%s\n' "${@}"
}

model() {
	local -a fish counts
	local i j

	mapfile -t fish <<< "$(tr "," '\n' < "${*}")"
	counts=(0 0 0 0 0 0 0 0 0)

	for i in "${fish[@]}"; do
		((counts[i]++))
	done

	for ((i = 0; i < days; i++)); do
		((j = counts[0]))
		mapfile -t counts <<< "$(shiftArray "${counts[@]}")"
		((counts[6] += j))
		counts[8]="${j}"
	done

	tr ' ' "+" <<< "${counts[@]}" | bc
}

main() {
	local opts days

	opts="$(getopt --options hd: --longoptions help,days: --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
			-d | --days )		days="${2}"; shift;;
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

	if grep --quiet '[^0-9,\r\n]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	model "${*}"
}

main "${@}"
