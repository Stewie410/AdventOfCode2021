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

getWinningBoard() {
	for (( i = 0; i < ( $(wc --lines < "${1}") / 5 ); i++ )); do
		sed --quiet "$((1 + (i * 5))),$((5 + (i * 5)))p" "${1}" | \
			awk --assign board="${i}" '
				/^(#\s){4}#$/ {
					print board
					exit 0
				}
				/#/ {
					for (i = 1; i <= 5; i++)
						if ($i == "#")
							cols[i]++
				}
				END {
					for (i = 1; i <= 5; i++) {
						if (cols[i] == 5) {
							print board
							exit 0
						}
					}
					exit 1
				}
			' && return
	done
}

getBoardScore() {
	sed --quiet "$((1 + (${1} * 5))),$((5 + (${1} * 5)))p" "${2}" | \
		sed 's/#/0/g;s/ /+/g' | \
		paste --serial --delimiter="+" | \
		bc
}

game_v2() {
	local -a numbers
	local boards score board
	boards="$(mktemp)"

	mapfile -t numbers <<< "$(head -1 "${1}" | tr ',' "\n")"
	sed 1,2d "${1}" | sed 's/^ /0/;s/  / 0/g;/^\s*$/d' > "${boards}"

	for i in "${numbers[@]}"; do
		(( ${#i} == 1 )) && i="0${i}"
		sed -i'' "s/${i}/#/g" "${boards}"
		board="$(getWinningBoard "${boards}")"
		if [ -n "${board}" ]; then
			score="$(getBoardScore "${board}" "${boards}")"
			sed --quiet "$((1 + (board * 5))),$((5 + (board * 5)))p" "${boards}" | column -t
			printf '%s\n' "Board: ${board}" "Base: ${score}" "Last: ${i}" "Score: $((i * score))"
			break
		fi
	done

	rm -f "${boards}"
	((score))
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

	game_v2 "${*}"
}

trap 'find /tmp -type f -name "board.*" -exec rm --force {} +' EXIT

main "${@}"
