#!/usr/bin/env bash

# Prevent tainting variables via environment
# See: https://gist.github.com/duxsco/fad211d5828e09d0391f018834f955c9
unset COLOR_OFF COLOR_RED COLOR_YELLOW GNUPG_COMMAND INDENTATION SED SED_REGEX

COLOR_RED='\e[0;1;97;101m'
COLOR_YELLOW='\e[0;1;30;103m'
COLOR_OFF='\e[0m'

if [[ $(uname -s) == Darwin ]]; then
    SED="gsed"
else
    SED="sed"
fi

function help() {
    echo -e "
Execute:
  $ bash ${0##*/} /path/to/gnupg/config/file.conf

The complete \"OPTIONS\" section of the manpage is printed out.
Options which have been set in the selected config file
are highlighted ${COLOR_RED}red${COLOR_OFF}.
The word \"default\" is highlighted ${COLOR_YELLOW}yellow${COLOR_OFF}.
"
}

function myMan() {
    man -P "cat -v" "$1" | ${SED} 's/\(.\)\^H\(.\)/\2/g'
}

if [[ $# -ne 1 ]] || [[ -z $1 ]]; then
    help
    exit 1
fi

SED_REGEX="$(grep -E -o "^[^#^[:space:]]*" "$1" | paste -d '|' -s -)"
# shellcheck disable=SC2001
GNUPG_COMMAND="$(${SED} 's/\.conf$//' <<<"${1##*/}")"
INDENTATION="$(
    myMan "${GNUPG_COMMAND}" | \
        ${SED} -n "/^OPTIONS/,/^[[:upper:]]/p" | \
        grep "^[[:space:]]*--" | \
        sort | tail -n 1 | \
        awk -F"--" '{print $1}'
)"

myMan "${GNUPG_COMMAND}" | \
    ${SED} -n '/^OPTIONS/,/^[[:upper:]]/p' | \
    head -n-1 | \
    ${SED} -E "s/^(${INDENTATION}--)(${SED_REGEX})($| )(.*)/\1$(printf "${COLOR_RED}%s${COLOR_OFF}" "\2")\3\4/g" | \
    ${SED} -E "s/([^-])(default)([^-])/\1$(printf "${COLOR_YELLOW}%s${COLOR_OFF}" "\2")\3/gi"
