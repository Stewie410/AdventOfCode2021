#!/usr/bin/env bash
#
# Description

# Show Help/Usage
show_help() {
	cat << EOF
Description

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-2, --part-two	Part-Two Solution
EOF
}

flash() {
	((flashes++))
	((stack[y * 10 + x] = -1))

	((y - 1 >= 0)) && ((stack[(y - 1) * 10 + x] != -1)) && ((stack[(y - 1) * 10 + x]++))
	((y + 1 < 10)) && ((stack[(y + 1) * 10 + x] != -1)) && ((stack[(y + 1) * 10 + x]++))
	((x - 1 >= 0)) && ((stack[y * 10 + (x - 1)] != -1)) && ((stack[y * 10 + (x - 1)]++))
	((x + 1 < 10)) && ((stack[y * 10 + (x + 1)] != -1)) && ((stack[y * 10 + (x + 1)]++))

	((x - 1 >= 0)) && ((y - 1 >= 0)) && ((stack[(y - 1) * 10 + (x - 1)] != -1)) && ((stack[(y - 1) * 10 + (x - 1)]++))
	((x + 1 < 10)) && ((y - 1 >= 0)) && ((stack[(y - 1) * 10 + (x + 1)] != -1)) && ((stack[(y - 1) * 10 + (x + 1)]++))
	((x - 1 >= 0)) && ((y + 1 < 10)) && ((stack[(y + 1) * 10 + (x - 1)] != -1)) && ((stack[(y + 1) * 10 + (x - 1)]++))
	((x + 1 < 10)) && ((y + 1 < 10)) && ((stack[(y + 1) * 10 + (x + 1)] != -1)) && ((stack[(y + 1) * 10 + (x + 1)]++))
}

isSurrounded() {
	((y - 1 >= 0)) || return 1
	((x - 1 >= 0)) || return 1
	((y + 1 < 10)) || return 1
	((x + 1 < 10)) || return 1

	((stack[y * 10 + (x - 1)] > 9)) || return 1
	((stack[y * 10 + (x + 1)] > 9)) || return 1
	((stack[(y - 1) * 10 + x] > 9)) || return 1
	((stack[(y + 1) * 10 + x] > 9)) || return 1

	((stack[(y - 1) * 10 + (x - 1)] > 9)) || return 1
	((stack[(y - 1) * 10 + (x + 1)] > 9)) || return 1
	((stack[(y + 1) * 10 + (x - 1)] > 9)) || return 1
	((stack[(y + 1) * 10 + (x + 1)] > 9)) || return 1

	return 0
}

printBoard() {
	local a b
	for ((a = 0; a < 10; a++)); do
		for ((b = 0; b < 10; b++)); do
			printf '%s' "${stack[$((a * 10 + b))]/0/_}"
		done
		printf '\n'
	done
	printf '\n'
}

part_one() {
	local -a stack
	local flashes i j x y
	flashes="0"

	mapfile -t stack <<< "$(grep --only-matching . "${*}")"

	printBoard

	for ((i = 0; i < 100; i++)); do
		for ((j = 0; j < 100; j++)); do
			((stack[j]++))
		done

		j="1"
		while ((j == 1)); do
			j="0"
			for ((y = 0; y < 10; y++)); do
				for ((x = 0; x < 10; x++)); do
					((stack[y * 10 + x] == -1)) && continue
					if ((stack[y * 10 + x] > 9)); then
						flash
						j="1"
					fi
				done
			done
		done

		for ((j = 0; j < 100; j++)); do
			((stack[j] == -1)) && ((stack[j] = 0))
		done

		printBoard
	done

	printf '%s\n' "${flashes}"
}

part_two() {
	local -a stack
	local i j x y

	mapfile -t stack <<< "$(grep --only-matching . "${*}")"

	printBoard

	for ((i = 1; i > 0; i++)); do
		for ((j = 0; j < 100; j++)); do
			((stack[j]++))
		done

		j="1"
		while ((j == 1)); do
			j="0"
			for ((y = 0; y < 10; y++)); do
				for ((x = 0; x < 10; x++)); do
					((stack[y * 10 + x] == -1)) && continue
					if ((stack[y * 10 + x] > 9)); then
						flash
						j="1"
					fi
				done
			done
		done

		for ((j = 0; j < 100; j++)); do
			((stack[j] == -1)) && ((stack[j] = 0))
		done

		printBoard

		if ! grep --quiet '[^0 ]' <<< "${stack[@]}"; then
			printf '%s\n' "${i}"
			return 0
		fi
	done

	return 1
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
