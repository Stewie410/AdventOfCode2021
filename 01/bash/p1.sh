#!/usr/bin/env bash
#
# Get the number of increases/decreases from previous measurement


# Show Help/Usage
show_help() {
	cat << EOF
Get the number of increases/decreases from previous measurement

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-i, --increase	Show the number of increases (default)
	-d, --decrease	Show the number of decreases
EOF
}

increases() {
	local count last
	local -a data

	mapfile -t data < "${1}"

	last="${data[0]}"
	for i in "${data[@]:1}"; do
		(( i > last )) && count="$((count + 1))"
		last="${i}"
	done

	printf '%s\n' "Increases: ${count}"
}

decreases() {
	local count last
	local -a data

	mapfile -t data < "${1}"

	last="${data[0]}"
	for i in "${data[@]:1}"; do
		(( i < last )) && count="$((count + 1))"
		last="${i}"
	done

	printf '%s\n' "Decreases: ${count}"
}

main() {
	local decrease opts

	opts="$(getopt --options hid --longoptions help,increase,decrease --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
			-i | --increase )	unset decrease;;
			-d | --decrease )	decrease="1";;
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
		printf '%s\n' "Input file does not contain data" >&2
		return 1
	fi

	if grep --quiet --extended-regexp '[^0-9\r\n]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	if [ -n "${decrease}" ]; then
		decreases "${*}"
	else
		increases "${*}"
	fi

	return 0
}

main "${@}"
