#!/usr/bin/env bash
#
# Calculate power consumption from binary diagnostic data

# Show Help/Usage
show_help() {
	cat << EOF
Calculate power consumption from binary diagnostic data

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
EOF
}


calculate() {
	local -a data bin zero one
	local gamma epsilon

	mapfile -t data < "${1}"

	for i in "${data[@]}"; do
		mapfile -t bin <<< "$(grep --only-matching . <<< "${i}")"
		for ((j = 0; j < ${#bin[@]}; j++)); do
			if ((bin[j])); then
				one[${j}]="$((one[j] + 1))"
			else
				zero[${j}]="$((zero[j] + 1))"
			fi
		done
	done

	for ((i = 0; i < ${#one[@]}; i++)); do
		if ((one[i] > zero[i])); then
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
