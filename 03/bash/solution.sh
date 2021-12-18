#!/usr/bin/env bash
#
# Calculate the power-consumption & life-support ratings from binary diagnostic data

# Show Help/Usage
show_help() {
	cat << EOF
Calculate the power-consumption & life-support ratings from binary diagnostic data

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-p, --power		Calculate the power consumption rating from INPUT (default)
	-l, --life		Calculate the life support rating from INPUT
EOF
}

main() {
	local opts power life

	opts="$(getopt --options hpl --longoptions help,power,life --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )	show_help; return 0;;
			-p | --power )	power="1";;
			-l | --life )	life="1";;
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

	[ -n "${power}" ] && getPower "${*}"
	[ -n "${life}" ] && getLife "${*}"
	return 0
}

getLife() {
	local gen scrub bit tmp
	tmp="$(mktemp)"

	# Generator
	bit="$(getMostCommonVal 1 "${1}")"
	sed --quiet "/^${bit}/p" "${1}" > "${tmp}"
	for (( i = 2; $(grep . --count "${tmp}") > 1; i++ )); do
		bit="$(getMostCommonVal "${i}" "${tmp}")"
		sed -i'' --quiet "/^[0-9]\{$((i - 1))\}${bit}/p" "${tmp}"
	done
	read -r gen < "${tmp}"

	# Scrubber
	bit="$(getMostCommonVal 1 "${1}")"
	sed --quiet "/^$((1 - bit))/p" "${1}" > "${tmp}"
	for (( i = 2; $(grep . --count "${tmp}") > 1; i++ )); do
		bit="$(getMostCommonVal "${i}" "${tmp}")"
		sed -i'' --quiet "/^[0-9]\{$((i - 1))\}$((1 - bit))/p" "${tmp}"
	done
	read -r scrub < "${tmp}"

	rm --force "${tmp}"
	cat <<- EOF
		O2 Generator:	${gen} ($((2#${gen})))
		CO2 Scrubber:	${scrub} ($((2#${scrub})))
		Life Support:	$(( (2#${gen}) * (2#${scrub}) ))
	EOF
}

getPower() {
	local gamma epsilon

	for (( i = 1; i <= $(head -1 "${1}" | grep --only-matching . | wc --lines); i++ )); do
		if (( $(getMostCommonVal "${i}" "${1}") == 1)); then
			gamma+="1"
			epsilon+="0"
		else
			gamma+="0"
			epsilon+="1"
		fi
	done

	cat <<- EOF
		Gamma Rate:		${gamma} ($((2#${gamma})))
		Epsilon Rate:		${epsilon} ($((2#${epsilon})))
		Power Consumption:	$(( (2#${gamma}) * (2#${epsilon}) ))
	EOF
}

getMostCommonVal() {
	cut --characters="${1}" "${2}" | \
		sort | \
		uniq --count | \
		sort --reverse | \
		xargs | \
		cut --fields="2" --delimiter=" "
}

main "${@}"
