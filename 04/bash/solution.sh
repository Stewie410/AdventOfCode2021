#!/usr/bin/env bash
#
# Get bingo-board winner

# Show Help/Usage
show_help() {
	cat << EOF
Get bingo-board winner

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-f, --first		Get first board to win
	-l, --last		Get last board to win
	-q, --quiet		Do not print status messages
EOF
}

isWinner() {
	local -a board
	local str x y
	mapfile -t board <<< "$(tr " " '\n' <<< "${1}")"
	for x in {0..4}; do
		[[ "${board[*]:$((x * 5))}" == "${2} ${2} ${2} ${2} ${2}" ]] && return 0
		for y in {0..4}; do str+="${board[$((y * 5 + x))]}"; done
		[[ "${str}" == "${2}${2}${2}${2}${2}" ]] && return 0
		unset str
	done
	return 1
}

getBaseScore() {
	tr " " '+' <<< "${*}" | bc
}

game() {
	local -a numbers boards
	local remaining mark i j

	mapfile -t numbers <<< "$(head -1 "${*}" | tr "," '\n')"
	mapfile -t boards <<< "$(sed '1,2d;/^\s*$/d;s/^ /0/;s/  / 0/g' "${*}" | paste --delimiter=" " - - - - -)"
	remaining="${#boards[@]}"
	mark="#"

	for i in "${numbers[@]}"; do
		((${#i} == 1)) && i="0${i}"
		[ -z "${quiet}" ] && printf '%s\n' "Current Number: '${i}'"
		for ((j = 0; j < ${#boards[@]}; j++)); do
			[ -z "${quiet}" ] && printf '%s\n' "Board ${j}: '${boards[${j}]}'"
			if [[ "${boards[${j}]}" != "winner" ]]; then
				boards[${j}]="${boards[${j}]//${i}/${mark}}"
				if isWinner "${boards[${j}]}" "${mark}"; then
					if ((remaining == ${#boards[@]})) && [ -n "${first}" ]; then
						cat <<- EOF
						FIRST WINNING BOARD

						CELLS:
						EOF
						tr " " '\n' <<< "${boards[${j}]}" | paste --delimiter=" " - - - - - | column -t | sed 's/^/\t/'
						cat <<- EOF
							BOARD:		${j}
							BASE SCORE:	$(getBaseScore "${boards[${j}]//${mark}/0}")
							LAST NUMBER:	${i}
							FINAL SCORE:	$(($(getBaseScore "${boards[${j}]//${mark}/0}") * i))
						EOF
						[ -z "${last}" ] && return 0
					fi
					if ((remaining == 1)) && [ -n "${last}" ]; then
						[ -n "${first}" ] && printf '\n%s\n\n' "-----"
						cat <<- EOF
						LAST WINNING BOARD

						CELLS:
						EOF
						tr " " '\n' <<< "${boards[${j}]}" | paste --delimiter=" " - - - - - | column -t | sed 's/^/\t/'
						cat <<- EOF
							BOARD:		${j}
							BASE SCORE:	$(getBaseScore "${boards[${j}]//${mark}/0}")
							LAST NUMBER:	${i}
							FINAL SCORE:	$(($(getBaseScore "${boards[${j}]//${mark}/0}") * i))
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
	local opts first last quiet

	opts="$(getopt --options hflq --longoptions help,first,last,quiet --name "${0##*/}" -- "${@}")"
	eval set -- "${opts}"
	while true; do
		case "${1}" in
			-h | --help )		show_help; return 0;;
			-f | --first )		first="1";;
			-l | --last )		last="1";;
			-q | --quiet )		quiet="1";;
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

	if grep --quiet '[^0-9\r\n ,]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	if [ -z "${first}" ] && [ -z "${last}" ]; then
		printf '%s\n' "Must specify if first or last winner should be calculated" >&2
		return 1
	fi

	game "${*}"
}

main "${@}"
