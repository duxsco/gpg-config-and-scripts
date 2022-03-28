#!/usr/bin/env bash

# Prevent tainting variables via environment
# See: https://gist.github.com/duxsco/fad211d5828e09d0391f018834f955c9
unset COLOR COLOR_OFF PUBLIC_KEYS TRUST_LEVEL XARGS

declare -A COLOR
COLOR["u"]='\e[0;1;97;106m'
COLOR["f"]='\e[0;1;97;104m'
COLOR["m"]='\e[0;1;30;103m'
COLOR["q"]='\e[0;1;97;105m'
COLOR["-|e|n|r|\?"]='\e[0;1;97;101m'
COLOR_OFF="\e[0m"

if [[ $(uname -s) == Darwin ]]; then
    XARGS="gxargs"
else
    XARGS="xargs"
fi

function deleteUntrustedPublicKeys() {
    gpg --list-keys --with-colons | \
        grep -E "^pub:(-|e|n|r|\?)" | \
        cut -d: -f5 | \
        ${XARGS} --no-run-if-empty gpg --delete-keys
}

function help() {
    echo -e "
Not trusted public keys are highlighted in ${COLOR["-|e|n|r|\?"]}red${COLOR_OFF} at the bottom of the public key list:
  - ${COLOR["-|e|n|r|\?"]}\"unknown\"${COLOR_OFF}
  - ${COLOR["-|e|n|r|\?"]}\"expired\"${COLOR_OFF}
  - ${COLOR["-|e|n|r|\?"]}\"never trust\"${COLOR_OFF}
  - ${COLOR["-|e|n|r|\?"]}\"revoked\"${COLOR_OFF}
  - ${COLOR["-|e|n|r|\?"]}\"error\"${COLOR_OFF}

Every other public key:
  - ${COLOR["u"]}\"ultimate\"${COLOR_OFF}
  - ${COLOR["f"]}\"full\"${COLOR_OFF}
  - ${COLOR["m"]}\"marginal\"${COLOR_OFF}
  - ${COLOR["q"]}\"undefined\"${COLOR_OFF}

List public keys:
  \$ bash ${0##*/}

Delete ${COLOR["-|e|n|r|\?"]}not trusted${COLOR_OFF} public keys:
  \$ bash ${0##*/} -d
"
}

function listPublicKeys() {
    PUBLIC_KEYS="$(gpg --list-keys --with-colons | grep "^pub:")"

    for TRUST_LEVEL in "u" "f" "m" "q" "-|e|n|r|\?"; do
        ( grep -E "^pub:(${TRUST_LEVEL}):" <<< "${PUBLIC_KEYS}" || true ) | \
            cut -d: -f5 | \
            ${XARGS} --no-run-if-empty gpg --list-options show-unusable-uids,show-sig-expire --list-keys | \
            sed -E "s/^(uid[[:space:]]*)( \[.*\] )(.*)/\1$(printf "${COLOR[$TRUST_LEVEL]}%s${COLOR_OFF}" "\2")\3/"
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
