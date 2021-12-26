#!/usr/bin/env bash
#
# Calculate the fuel consumption

# Show Help/Usage
show_help() {
	cat << EOF
Calculate the fuel consumption

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-2, --part-two	Part Two solution
EOF
}

calculate() {
	local -a crab
	local i j ceiling least position distance
	ceiling="0"

	while read -r i j; do
		((crab[j] = i))
		((j > ceiling)) && ceiling="${j}"
	done <<< "$(tr "," '\n' < "${*}" | sort --numeric-sort | uniq --count | sed 's/^\s*//')"

	if [ -n "${p2}" ]; then
		for ((i = 0; i <= ceiling; i++)); do
			cost="0"
			for j in "${!crab[@]}"; do
				((distance = j - i))
				distance="${distance/-/}"
				((cost += ((distance**2 + distance) / 2) * crab[j]))
			done
			if [ -z "${least}" ] || ((cost < least)); then
				least="${cost}"
				position="${i}"
			fi
			#printf '%s: %s\n' "${i}" "${cost}"
		done
	else
		for ((i = 0; i <= ceiling; i++)); do
			cost="0"
			for j in "${!crab[@]}"; do
				((distance = j - i))
				distance="${distance/-/}"
				((cost += distance * crab[j]))
			done
			if [ -z "${least}" ] || ((cost < least)); then
				least="${cost}"
				position="${i}"
			fi
			#printf '%s: %s\n' "${i}" "${cost}"
		done
	fi

	printf 'Cheapest Fuel Cost: %s (%s)\n' "${least}" "${position}"
}

main() {
	local opts p2

	opts="$(getopt --options h2 --longoptions help,part-two --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
			-2 | --part-two )	p2="1";;
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

	calculate "${@}"
}

main "${@}"
