#!/usr/bin/env bash
#
# Get risk levels from heightmap

# Show Help/Usage
show_help() {
	cat << EOF
Get risk levels from heightmap

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-2, --part-two	Part-Two Solution
EOF
}

getAdjacents() {
	((x + 1 < width)) && printf '%s\n' "${map[$((y * width + (x + 1)))]}"
	((x - 1 >= 0)) && printf '%s\n' "${map[$((y * width + (x - 1)))]}"
	((y + 1 < height)) && printf '%s\n' "${map[$(((y + 1) * width + x))]}"
	((y - 1 >= 0)) && printf '%s\n' "${map[$(((y - 1) * width + x))]}"
}

# X Y
getGroup() {
	((${2} < 0)) && return
	((${2} >= height)) && return
	((${1} < 0)) && return
	((${1} >= width)) && return
	((map[${2} * width + ${1}] == 9)) && return
	((map[${2} * width + ${1}] == -1)) && return
	((map[${2} * width + ${1}] = -1))
	((groups[${#groups[@]} - 1]++))
	getGroup "$((${1} + 1))" "${2}"
	getGroup "$((${1} - 1))" "${2}"
	getGroup "${1}" "$((${2} + 1))"
	getGroup "${1}" "$((${2} - 1))"
}

part_one() {
	local -a map
	local width height sum x y

	width="$(head -1 "${*}" | awk '{print length($0)}')"
	height="$(wc --lines < "${*}")"
	mapfile -t map <<< "$(grep --only-matching . < "${*}")"
	sum="0"

	for ((y = 0; y < height; y++)); do
		for ((x = 0; x < width; x++)); do
			((map[y * width + x] < $(getAdjacents | sort --numeric-sort | head -1))) && ((sum += map[y * width + x] + 1))
		done
	done

	printf '%s\n' "${sum}"
}

part_two() {
	local -a map groups
	local width height x y

	width="$(head -1 "${*}" | awk '{print length($0)}')"
	height="$(wc --lines < "${*}")"
	mapfile -t map <<< "$(grep --only-matching . < "${*}")"

	for ((y = 0; y < height; y++)); do
		for ((x = 0; x < width; x++)); do
			groups+=(0)
			getGroup "${x}" "${y}"
		done
	done

	printf '%s\n' "${groups[@]}" | sort --numeric-sort --reverse | head -3 | paste --serial --delimiter="*" | bc
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
		printf '%s\n' "Input file does not contain data" >&2
		return 1
	fi

	if grep --quiet '[^0-9\r\n]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	if [ -n "${p2}" ]; then
		part_two "${*}"
		return
	fi

	part_one "${*}"
}

main "${@}"
