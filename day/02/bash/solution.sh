#!/usr/bin/env bash
#
# Calculated the horizontal position Description depth

# Show Help/Usage
show_help() {
	cat << EOF
Calculated the horizontal position Description depth

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-a, --aim		Assume up/down adjusts aim
EOF
}

simple() {
	local i j x y

	while read -r i j; do
		case "${i,,}" in
			forward )	x="$((x + j))";;
			down )		y="$((y + j))";;
			up )		y="$((y - j))";;
		esac
	done < "${1}"


	cat <<- EOF
		Position:	${x}
		Depth:		${y}
		Solution:	$((x * y))
	EOF
}

withAim() {
	local i j x y a

	while read -r i j; do
		case "${i,,}" in
			forward )	x="$((x + j))"; y="$((y + (a * j)))";;
			down )		a="$((a + j))";;
			up )		a="$((a - j))";;
		esac
	done < "${1}"

	cat <<- EOF
		Position:	${x}
		Depth:		${y}
		Aim:		${a}
		Solution:	$((x * y))
	EOF
}


main() {
	local opts aim

	opts="$(getopt --options ha --longoptions help --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )	show_help; return 0;;
			-a | --aim )	aim="1";;
			-- )			shift; break;;
			* )				break;;
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

	if grep --quiet --ignore-case --invert-match --extended-regexp '^(forward|up|down) [0-9]+$' "${*}"; then
		printf '%s\n' "Input file contains invalid commands" >&2
		return 1
	fi

	if [ -n "${aim}" ]; then
		withAim "${*}"
	else
		simple "${*}"
	fi
}

main "${@}"
