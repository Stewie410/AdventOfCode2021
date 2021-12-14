#!/usr/bin/env bash
#
# Calculate the life support rating from binary diagnostic data

# Show Help/Usage
show_help() {
	cat << EOF
Calculate the life support rating from binary diagnostic data

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
EOF
}

calculate() {
	local gen scrub bit tmp
	tmp="$(mktemp)"

	# Generator
	bit="$(getMostCommonVal 1 "${1}")"
	sed -n "/^${bit}/p" "${1}" > "${tmp}"
	for (( i = 2; $(wc --lines "${tmp}" | cut --fields=1 --delimiter=" ") > 1; i++ )); do
		bit="$(getMostCommonVal "${i}" "${tmp}")"
		sed -i'' --quiet "/^[01]\{$((i - 1))\}${bit}/p" "${tmp}"
	done
	gen="$(cat "${tmp}")"

	# Scrubber
	bit="$(( 1 - $(getMostCommonVal 1 "${1}") ))"
	sed -n "/^${bit}/p" "${1}" > "${tmp}"
	for (( i = 2; $(wc --lines "${tmp}" | cut --fields=1 --delimiter=" ") > 1; i++ )); do
		bit="$(getMostCommonVal "${i}" "${tmp}")"
		sed -i'' --quiet "/^[01]\{$((i - 1))\}$((1 - bit))/p" "${tmp}"
	done
	scrub="$(cat "${tmp}")"

	cat <<- EOF
		O2 Generator:	${gen} ($((2#${gen})))
		CO2 Scrubber:	${scrub} ($((2#${scrub})))
		Life Support:	$(( (2#${gen}) * (2#${scrub}) ))
	EOF

	rm --force "${tmp}"
}

# get most common bit :: bit, file
getMostCommonVal() {
	sed 's/\([0-9]\)/\1 /g' "${2}" | \
		sed 's/ $//' | \
		cut --fields="${1}" --delimiter=" " | \
		sort | \
		uniq --count | \
		sed 's/^\s\+//' | \
		sort --reverse | \
		sed 1q | \
		cut --fields=2 --delimiter=" "
}

main() {
	local opts

	opts="$(getopt --options h --longoptions help --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )	show_help; return 0;;
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

	if grep --quiet --extended-regexp '[^01\r\n]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	calculate "${*}"
}

main "${@}"
