#!/usr/bin/env bash

# Prevent tainting variables via environment
# See: https://gist.github.com/duxsco/fad211d5828e09d0391f018834f955c9
unset color_off color_red color_yellow gnupg_command indentation sed sed_regex

color_red='\e[0;1;97;101m'
color_yellow='\e[0;1;30;103m'
color_off='\e[0m'

if [[ $(uname -s) == Darwin ]]; then
    sed="gsed"
else
    sed="sed"
fi

function help() {
    echo -e "
Execute:
  $ bash ${0##*/} /path/to/gnupg/config/file.conf

The complete \"OPTIONS\" section of the manpage is printed out.
Options which have been set in the selected config file
are highlighted ${color_red}red${color_off}.
The word \"default\" is highlighted ${color_yellow}yellow${color_off}.
"
}

function myMan() {
    man -P "cat -v" "$1" | ${sed} 's/\(.\)\^H\(.\)/\2/g'
}

if [[ $# -ne 1 ]] || [[ -z $1 ]]; then
    help
    exit 1
fi

sed_regex="$(grep -E -o "^[^#^[:space:]]*" "$1" | paste -d '|' -s -)"
# shellcheck disable=SC2001
gnupg_command="$(${sed} 's/\.conf$//' <<<"${1##*/}")"
indentation="$(
    myMan "${gnupg_command}" | \
        ${sed} -n "/^OPTIONS/,/^[[:upper:]]/p" | \
        grep "^[[:space:]]*--" | \
        sort | tail -n 1 | \
        awk -F"--" '{print $1}'
)"

myMan "${gnupg_command}" | \
    ${sed} -n '/^OPTIONS/,/^[[:upper:]]/p' | \
    head -n-1 | \
    ${sed} -E "s/^(${indentation}--)(${sed_regex})($| )(.*)/\1$(printf "${color_red}%s${color_off}" "\2")\3\4/g" | \
    ${sed} -E "s/([^-])(default)([^-])/\1$(printf "${color_yellow}%s${color_off}" "\2")\3/gi"
