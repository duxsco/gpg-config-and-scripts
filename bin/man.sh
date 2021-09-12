#!/usr/bin/env bash

set -euo pipefail

unset PRINT_FULL_GNUPG_MANPAGE
unset GNUPG_CONFIG_FILE

COLOR_RED='\e[0;1;97;101m'
COLOR_YELLOW='\e[0;1;30;103m'
COLOR_OFF='\e[0m'

help() {
    echo -e "
Execute:
  $ bash ${0##*/} -c /path/to/gnupg/config/file.conf [-f]

Optional flag \"-f\" outputs the complete \"OPTIONS\" section of the manpage.

Config file options are highlighted ${COLOR_RED}red${COLOR_OFF}.
The word \"default\" is highlighted ${COLOR_YELLOW}yellow${COLOR_OFF}.
"

return 1
}

while getopts c:fh opt; do
    case $opt in
        c)
            GNUPG_CONFIG_FILE="${OPTARG}";;
        f)
            PRINT_FULL_GNUPG_MANPAGE="true";;
        h|*)
            help;;
   esac
done

if [ -z ${GNUPG_CONFIG_FILE+x} ]; then
    help
fi

SED_REGEX="$(
    grep '^[[:lower:]]' "${GNUPG_CONFIG_FILE}" | \
        awk '{print $1}' | \
        paste -d '|' -s -
)"
# shellcheck disable=SC2001
GNUPG_COMMAND="$(sed 's/\.conf$//' <<<"${GNUPG_CONFIG_FILE##*/}")"
INDENTATION="$(
    man "${GNUPG_COMMAND}" | \
        sed -n "/^OPTIONS/,/^[[:upper:]]/p" | \
        grep "^[[:space:]]*--" | \
        sort | tail -n 1 | \
        awk -F"--" '{print $1}'
)"

if [ -z ${PRINT_FULL_GNUPG_MANPAGE+x} ]; then
    man "${GNUPG_COMMAND}" | \
        sed -n -E "/^${INDENTATION}--(${SED_REGEX})($| )/,/^$/p" | \
        sed -E "s/([^-])(default)([^-])/\1$(printf "${COLOR_YELLOW}%s${COLOR_OFF}" "\2")\3/gi"
else
    man "${GNUPG_COMMAND}" | \
        sed -n '/^OPTIONS/,/^[[:upper:]]/p' | \
        sed -E "s/^(${INDENTATION}--)(${SED_REGEX})($| )(.*)/\1$(printf "${COLOR_RED}%s${COLOR_OFF}" "\2")\3\4/g" | \
        sed -E "s/([^-])(default)([^-])/\1$(printf "${COLOR_YELLOW}%s${COLOR_OFF}" "\2")\3/gi"
fi
