#!/usr/bin/env bash

# Prevent tainting variables via environment
# See: https://gist.github.com/duxsco/fad211d5828e09d0391f018834f955c9
unset color color_off public_keys trust_level xargs

declare -A color
color["u"]='\e[0;1;97;106m'
color["f"]='\e[0;1;97;104m'
color["m"]='\e[0;1;30;103m'
color["q"]='\e[0;1;97;105m'
color["-|e|n|r|\?"]='\e[0;1;97;101m'
color_expired='\e[0;1;97;101m'
color_off="\e[0m"

if [[ $(uname -s) == Darwin ]]; then
    xargs="gxargs"
else
    xargs="xargs"
fi

function deleteUntrustedPublicKeys() {
    gpg --list-keys --with-colons | \
        grep -E "^pub:(-|e|n|r|\?)" | \
        cut -d: -f5 | \
        ${xargs} --no-run-if-empty gpg --delete-keys
}

function help() {
    echo -e "
Not trusted public keys are highlighted in ${color["-|e|n|r|\?"]}red${color_off} at the bottom of the public key list:
  - ${color["-|e|n|r|\?"]}\"unknown\"${color_off}
  - ${color["-|e|n|r|\?"]}\"expired\"${color_off}
  - ${color["-|e|n|r|\?"]}\"never trust\"${color_off}
  - ${color["-|e|n|r|\?"]}\"revoked\"${color_off}
  - ${color["-|e|n|r|\?"]}\"error\"${color_off}

Every other public key:
  - ${color["u"]}\"ultimate\"${color_off}
  - ${color["f"]}\"full\"${color_off}
  - ${color["m"]}\"marginal\"${color_off}
  - ${color["q"]}\"undefined\"${color_off}

List public keys:
  \$ bash ${0##*/}

Delete ${color["-|e|n|r|\?"]}not trusted${color_off} public keys:
  \$ bash ${0##*/} -d
"
}

function listPublicKeys() {
    public_keys="$(gpg --list-keys --with-colons | grep "^pub:")"

    for trust_level in "u" "f" "m" "q" "-|e|n|r|\?"; do
        # shellcheck disable=SC2059
        ( grep -E "^pub:(${trust_level}):" <<< "${public_keys}" || true ) | \
            cut -d: -f5 | \
            ${xargs} --no-run-if-empty gpg --list-options show-unusable-uids,show-unusable-subkeys,show-sig-expire --list-keys | \
            sed -E "s/expired/$(printf "${color_expired}expired${color_off}")/" | \
            sed -E "s/^(uid[[:space:]]*)( \[.*\] )(.*)/\1$(printf "${color[$trust_level]}%s${color_off}" "\2")\3/"
    done
}

while getopts dh opt; do
    case $opt in
        d)
            deleteUntrustedPublicKeys
            exit 0
            ;;
        h)
            help
            exit 0
            ;;
        ?)
            help
            exit 1
            ;;
    esac
done

if [[ $# -eq 0 ]]; then
    listPublicKeys
else
    help
    exit 1
fi
