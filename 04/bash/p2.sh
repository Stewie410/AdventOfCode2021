#!/usr/bin/env bash
#
# Determine the last winning bingo board

# Show Help/Usage
show_help() {
	cat << EOF
Determine the last winning bingo board

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
EOF
}

isWinner() {
	local -a board
	local str x y

	mapfile -t board <<< "$(tr ' ' '\n' <<< "${1}")"

	for x in {0..4}; do
		[[ "${board[*]:$((x * 5)):5}" == "${2} ${2} ${2} ${2} ${2}" ]] && return 0
		for y in {0..4}; do
			str+="${board[$((y * 5 + x))]}"
		done
		[[ "${str}" == "${2}${2}${2}${2}${2}" ]] && return 0
		unset str
	done

	return 1
}

getBase() {
	tr ' ' '+' <<< "${*}" | bc
}

game() {
	local -a numbers boards
	local remaining mark i j

	mapfile -t numbers <<< "$(head -1 "${1}" | tr ',' '\n')"
	mapfile -t boards <<< "$(sed '1,2d;/^\s*$/d;s/^ /0/;s/  / 0/g' "${1}" | \
		paste --delimiter=" " - - - - -)"
	remaining="${#boards[@]}"
	mark="#"

	for i in "${numbers[@]}"; do
		#printf '%s\n' "number: ${i}"
		(( ${#i} == 1 )) && i="0${i}"
		for ((j = 0; j < ${#boards[@]}; j++)); do
			#printf '%s\n' "board: ${j}: ${boards[${j}]}"
			if [[ "${boards[${j}]}" != "winner" ]]; then
				boards[${j}]="${boards[${j}]//${i}/${mark}}"
				if isWinner "${boards[${j}]}" "${mark}"; then
					if ((remaining == 1)); then
						tr " " '\n' <<< "${boards[${j}]}" | paste --delimiter=" " - - - - - | column -t
						cat <<- EOF
							Board:	${j}
							Base:	$(getBase "${boards[${j}]//${mark}/0}")
							Last:	${i}
							Score:	$(($(getBase "${boards[${j}]//${mark}/0}") * i))
						EOF
						return 0
					fi
					boards[${j}]="winner"
					remaining="$((remaining - 1))"
				fi
			fi
		done
	done

	return 1
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
