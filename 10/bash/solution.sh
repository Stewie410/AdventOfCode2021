#!/usr/bin/env bash
#
# Score navigational data

# Show Help/Usage
show_help() {
	cat << EOF
Score navigational data

USAGE: ${0##*/} [OPTIONS] INPUT

OPTIONS:
	-h, --help		Show this help message
	-2, --part-two	Part-Two Solution
EOF
}

getClosingChar() {
	local c
	case "${1}" in
		"[" )	c="]";;
		"(" )	c=")";;
		"{" )	c="}";;
		"<" )	c=">";;
	esac
	printf '%s\n' "${c}"
}

getIllegalCharScore() {
	local c
	case "${1}" in
		")" )	c="3";;
		"]" )	c="57";;
		"}" )	c="1197";;
		">" )	c="25137";;
	esac
	printf '%s\n' "${c}"
}

getCompletionCharScore() {
	local c
	case "${1}" in
		")" )	c="1";;
		"]" )	c="2";;
		"}" )	c="3";;
		">" )	c="4";;
	esac
	printf '%s\n' "${c}"
}

getIllegalScore() {
	local -a stack
	local char

	while read -r char; do
		if [[ "${char}" =~ [\[\{\(\<] ]]; then
			stack+=("${char}")
		elif [[ "${char}" != "$(getClosingChar "${stack[-1]}")" ]]; then
			getIllegalCharScore "${char}"
			return
		else
			unset 'stack[-1]'
		fi
	done <<< "$(grep --only-matching . <<< "${*}")"

	printf '%s\n' "0"
}

getCompletionScore() {
	local -a stack
	local char result

	while read -r char; do
		if [[ "${char}" =~ [\[\{\(\<] ]]; then
			stack+=("${char}")
		elif [[ "${char}" == "$(getClosingChar "${stack[-1]}")" ]]; then
			unset 'stack[-1]'
		else
			printf '%s\n' "0"
			return 1
		fi
	done <<< "$(grep --only-matching . <<< "${*}")"

	mapfile -t stack <<< "$(rev <<< "${stack[@]}" | tr " " '\n')"
	result="0"
	for char in "${stack[@]}"; do
		((result = (result * 5) + $(getCompletionCharScore "$(getClosingChar "${char}")")))
	done

	printf '%s\n' "${result}"
}

part_one() {
	local line sum
	sum="0"

	while read -r line; do
		((sum += $(getIllegalScore "${line}")))
	done < "${*}"

	printf '%s\n' "${sum}"
}

part_two() {
	local -a scores
	local line

	while read -r line; do
		scores+=("$(getCompletionScore "${line}")")
		((scores[-1] == 0)) && unset 'scores[-1]'
	done < "${*}"

	mapfile -t scores <<< "$(printf '%s\n' "${scores[@]}" | sort --numeric-sort)"

	printf '%s\n' "${scores[$((${#scores[@]} / 2))]}"
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

	if grep --quiet '[^\[\](){}<>\r\n]' "${*}"; then
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
