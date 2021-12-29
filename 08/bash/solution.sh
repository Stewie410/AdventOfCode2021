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
	-2, --part-two	Get the sum of all display outputs
EOF
}

filterSignals() {
	tr " " '\n' <<< "${*}" | while read -r sequence; do
		grep --only-matching . <<< "${sequence}" | sort | paste --serial --delimiter='\0'
	done
}

getDigits() {
	local -a ds sl
	local idx

	mapfile -t sl <<< "$(tr " " '\n' <<< "${*}")"

	# Unique Numbers
	for idx in "${sl[@]}"; do
		case "${#idx}" in
			2 ) ds[1]="${idx}";;
			3 ) ds[7]="${idx}";;
			4 ) ds[4]="${idx}";;
			7 ) ds[8]="${idx}";;
		esac
	done

	while ((${#ds[@]} < 10)); do
		for idx in "${sl[@]}"; do
			if ((${#idx} == 6)); then
				if [ -n "${ds[6]}" ]; then
					if [ -n "${ds[0]}" ]; then
						if [[ "${idx}" != "${ds[6]}" ]] && [[ "${idx}" != "${ds[0]}" ]]; then
							ds[9]="${idx}"
						fi
					elif [[ "${idx}" != "${ds[6]}" ]]; then
						if (($(grep --only-matching . <<< "${idx}" | grep "[${ds[4]}]" --count) == 3)); then
							ds[0]="${idx}"
						fi
					fi
				elif (($(grep --only-matching . <<< "${idx}" | grep "[${ds[1]}]" --count) == 1)); then
					ds[6]="${idx}"
				fi
			elif ((${#idx} == 5)); then
				if [ -n "${ds[5]}" ]; then
					if [ -n "${ds[3]}" ]; then
						if [[ "${idx}" != "${ds[5]}" ]] && [[ "${idx}" != "${ds[3]}" ]]; then
							ds[2]="${idx}"
							break 2
						fi
					elif [ -n "${ds[9]}" ] && [[ "${idx}" != "${ds[5]}" ]]; then
						if (($(grep --only-matching . <<< "${ds[9]}" | grep "[^${idx}]" --count) == 1)); then
							ds[3]="${idx}"
						fi
					fi
				elif [ -n "${ds[6]}" ]; then
					if (($(grep --only-matching . <<< "${ds[6]}" | grep "[^${idx}]" --count) == 1)); then
						ds[5]="${idx}"
					fi
				fi
			fi
		done
	done

	printf '%s\n' "${ds[@]}"
}

part_one() {
	local count digit
	count="0"

	while read -r digit; do
		case "${#digit}" in
			2 | 3 | 4 | 7 )		((count++));;
		esac
	done <<< "$(sed 's/^.*| //' "${*}" | tr " " '\n')"

	printf '%s\n' "Unique Digits: ${count}"
}

part_two() {
	local -a digits signals
	local line i j number sum

	while read -r line; do
		mapfile -t digits <<< "$(getDigits "$(filterSignals "${line/ | / }" | awk '!seen[$0]++' | paste --serial --delimiter=" ")")"
		mapfile -t signals <<< "$(filterSignals "$(sed 's/^.*| //' <<< "${line}")")"
		unset number
		for i in "${signals[@]}"; do
			for ((j = 0; j < 10; j++)); do
				if [[ "${digits[${j}]}" == "${i}" ]]; then
					number+="${j}"
				fi
			done
		done
		sum="$(bc <<< "${sum:-0} + ${number}")"
	done < "${*}"

	printf '%s\n' "${sum}"
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

	if grep --quiet '[^a-g| \r\n]' "${*}"; then
		printf '%s\n' "Input file contains invalid data" >&2
		return 1
	fi

	if ((p2)); then
		part_two "${*}"
		return
	fi

	part_one "${*}"
}

main "${@}"
