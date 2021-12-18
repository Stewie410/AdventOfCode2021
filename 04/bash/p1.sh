#!/usr/bin/env bash
#
# Determine winning bingo board

# Show Help/Usage
show_help() {
	cat << EOF
Determine winning bingo board

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
EOF
}

# File
isWinningBoard() {
	grep --quiet "#" "${1}" || return
	grep --extended-regexp '^#(\s+#){4}' "${1}" && return
	for idx in {1..5}; do
		awk --assign "idx=${idx}" '{print $(idx)}' "${1}" | tr --delete '\n' | grep --extended-regexp '^#{5}$' && return
	done
	return 1
}

game() {
	local -a boards numbers
	local count num

	mapfile -t numbers <<< "$(head -1 "${1}" | tr "," '\n')"

	count="$(grep '^\s*$' --count "${1}")"
	for ((i = 0; i < count; i++)); do
		boards[${i}]="$(mktemp board.XXXXXXXXXX)"
		sed --quiet "$((3+(i*6))),$((7+(i*6)))p" "${1}" > "${boards[${i}]}"
	done

	for i in "${numbers[@]}"; do
		num="${i}"
		(( ${#num} == 1 )) && num=" ${num}"
		for ((j = 0; j < ${#boards[@]}; j++)); do
			sed -i'' "s/${num}/#/g" "${boards[${j}]}"
			if isWinningBoard "${boards[${j}]}"; then
				winner="1"
				cat <<- EOF
					Winning Board:	${j}
					Score:		$((i * $(tr --delete '#' < "${boards[${j}]}" | xargs | tr ' ' "+" | bc) ))
					winning board:
				EOF
				sed 's/^/\t/' "${boards[${j}]}"
				break 2
			fi
		done
	done

	[ -n "${winner}" ] && return
	printf '%s\n' "No winning board" >&2
	return 1
}

game_v2() {
	local -a numbers
	local boards
	boards="$(mktemp bingo_board.XXXXXXXXXX)"

	mapfile -t numbers <<< "$(head -1 "${1}" | tr ',' "\n")"
	sed 1,2d "${1}" | sed 's/^ /0/;s/  / 0/g' > "${boards}"

	for i in "${numbers[@]}"; do
		#sed "s/\"${i}\"/"
	done
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
		printf '%s\n' "Input file contains no data" >&2
		return 1
	fi

	if ! grep --quiet '[0-9\r\n,]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	game "${*}"
}

trap 'find /tmp -type f -name "board.*" -exec rm --force {} +' EXIT

main "${@}"
