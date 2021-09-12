#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
cat <<EOF
Please, provide the ID of the key whose public key you want to retrieve.
Example:
  $ bash ${0##*/} 0xABCDEFGH01234567
  $ bash ${0##*/} max.mustermann@example.org

Aborting...

EOF

    exit 1
fi

declare -a FAIL
declare -a SUCCESS
TEMP_GPG_HOMEDIR="$(mktemp -d)"

# if e-mail...
if grep -q "@" <<<"$1"; then
    for MECHANISM in "dane" "wkd" "pka" "cert" "hkps://keys.openpgp.org" "hkps://keys.mailvelope.com" "hkps://keys.gentoo.org" "hkps://keyserver.ubuntu.com"; do
        gpg --homedir "${TEMP_GPG_HOMEDIR}" --locate-keys --auto-key-locate "clear,nodefault,${MECHANISM}" "$1" >/dev/null 2>&1 && \
        SUCCESS+=("${MECHANISM}") || \
        FAIL+=("${MECHANISM}")
    done
else
    for KEYSERVER in "hkps://keys.openpgp.org" "hkps://keys.mailvelope.com" "hkps://keys.gentoo.org" "hkps://keyserver.ubuntu.com"; do
        gpg --homedir "${TEMP_GPG_HOMEDIR}" --keyserver "${KEYSERVER}" --recv-keys "$1" >/dev/null 2>&1 && \
        SUCCESS+=("${KEYSERVER}") || \
        FAIL+=("${KEYSERVER}")
    done
fi

gpgconf --homedir "${TEMP_GPG_HOMEDIR}" --kill all

case "${#SUCCESS[@]}" in
    0)
        echo -e "\nNo working mechanism found! Aborting...\n";;
    *)
        echo -e "\nFollowing mechanism(s) are working for public key retrieval.\nWhat do you want to use?\n  0) Abort/Quit"

        for INDEX in "${!SUCCESS[@]}"; do
            echo "  $((INDEX+1))) ${SUCCESS[${INDEX}]}"
        done

        echo ""
        read -r -p "Please, select by number: " CHOICE
        echo ""


        NUMBER_REGEX='^[0-9]+$'
        if ! [[ ${CHOICE} =~ ${NUMBER_REGEX} ]] || [[ ${CHOICE} -gt ${#SUCCESS[@]} ]]; then
            echo -e "Invalid choice! Aborting...\n"
            exit 1
        fi

        if [[ ${CHOICE} -eq 0 ]]; then
            echo -e "Public key retrieval aborted!\n"
        else
            ((CHOICE--))
            echo -e "Mechanism \"${SUCCESS[${CHOICE}]}\" chosen...\n"
            gpg  --locate-keys --auto-key-locate "clear,nodefault,${SUCCESS[${CHOICE}]}" "$1"
        fi
        ;;
esac
