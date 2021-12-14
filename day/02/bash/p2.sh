#!/usr/bin/env bash
#
# Calculate horizontal position & depth after following INPUT commands

# Show Help/Usage
show_help() {
	cat << EOF
Calculate horizontal position & depth after following INPUT commands

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
EOF
}

calculate() {
	local position depth aim
	local -a commands

	mapfile -t commands < "${1}"

	for i in "${commands[@]}"; do
		i="${i,,}"
		case "${i% *}" in
			forward )
				position="$((position + ${i##* }))"
				depth="$((depth + (aim * ${i##* }) ))"
				;;
			down )		aim="$((aim + ${i##* }))";;
			up )		aim="$((aim - ${i##* }))";;
		esac
	done

	cat <<- EOF
		Position:	${position}
		Depth:		${depth}
		Aim:		${aim}
		Solution:	$(( position * depth ))
	EOF
}

main() {
	local opts

	opts="$(getopt --options h --longoptions help --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
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

	if grep --quiet --extended-regexp --invert-match --ignore-case '(forward|down|up) [0-9]+' "${*}"; then
		printf '%s\n' "Input file contains invalid commands" >&2
		return 1
	fi

	calculate "${*}"
}

main "${@}"
