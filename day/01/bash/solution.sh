#!/usr/bin/env bash
#
# Calculate the numebr of increases/decreases

# Show Help/Usage
show_help() {
	cat << EOF
Calculate the numebr of increases/decreases

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-i, --increase	Show the number of increases
	-d, --decrease	Show the number of decreases
	-w, --window	Use a 3-measurement sliding window
EOF
}

simple() {
	local last num inc dec

	last="$(head -1 "${1}")"
	while read -r num; do
		if ((num > last)); then
			inc="$((inc + 1))"
		elif ((num < last)); then
			dec="$((dec + 1))"
		fi
		last="${num}"
	done <<< "$(sed 1d "${1}")"

	[ -n "${increase}" ] && printf '%s\n' "Increases: ${inc}"
	[ -n "${decrease}" ] && printf '%s\n' "Decreases: ${dec}"
}

window() {
	local last current inc dec i
	local -a data

	mapfile -t data < "${1}"

	last="$((data[0] + data[1] + data[2]))"
	for ((i = 3; i < ${#data[@]}; i++)); do
		current="$((data[i] + data[i-1] + data[i-2]))"
		if ((current > last)); then
			inc="$((inc + 1))"
		elif ((current < last)); then
			dec="$((dec + 1))"
		fi
		last="${current}"
	done

	[ -n "${increase}" ] && printf '%s\n' "Increases: ${inc}"
	[ -n "${decrease}" ] && printf '%s\n' "Decreases: ${dec}"
}

main() {
	local opts increase decrease window
	opts="$(getopt --options hidw --longoptions help,increase,decrease,window --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
			-i | --increase )	increase="1";;
			-d | --decrease )	decrease="1";;
			-w | --window )		window="1";;
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
		printf '%s\n' "Input file does not contian data" >&2
		return 1
	fi

	if grep --quiet --extended-regexp '[^0-9]\r\n' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	if [ -n "${window}" ]; then
		window "${*}"
	else
		simple "${*}"
	fi

	return 0
}

main "${@}"
