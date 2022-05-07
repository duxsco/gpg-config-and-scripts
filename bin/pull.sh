#!/usr/bin/env bash

# Prevent tainting variables via environment
# See: https://gist.github.com/duxsco/fad211d5828e09d0391f018834f955c9
unset choice keyserver mechanism number_regex pka success temp_gpg_homedir

if [[ $# -ne 1 ]]; then
cat <<EOF
Please, provide the ID of the key whose public key you want to retrieve.
Example:
  $ bash ${0##*/} 0xABCDEFGH01234567
  $ bash ${0##*/} max.mustermann@example.org

Aborting...

EOF

    exit 1
fi

declare -a success
temp_gpg_homedir="$(mktemp -d)"

if grep -q '^gpg (GnuPG) 2\.2\.' < <(gpg --homedir "${temp_gpg_homedir}" --version); then
    pka="pka"
else
    pka=""
fi

# if e-mail...
if grep -q "@" <<<"$1"; then
    for mechanism in "dane" "wkd" ${pka} "cert" "hkps://keys.openpgp.org" "hkps://keys.mailvelope.com" "hkps://keys.gentoo.org" "hkps://keyserver.ubuntu.com"; do
        if gpg --homedir "${temp_gpg_homedir}" --auto-key-locate "clear,${mechanism}" --locate-external-key "$1" >/dev/null 2>&1; then
            success+=("${mechanism}")
        fi
    done
else
    for keyserver in "hkps://keys.openpgp.org" "hkps://keys.mailvelope.com" "hkps://keys.gentoo.org" "hkps://keyserver.ubuntu.com"; do
        if gpg --homedir "${temp_gpg_homedir}" --keyserver "${keyserver}" --recv-keys "$1" >/dev/null 2>&1; then
            success+=("${keyserver}")
        fi
    done
fi

gpgconf --homedir "${temp_gpg_homedir}" --kill all

if [[ ${#success[@]} -eq 0 ]]; then
    echo -e "\nNo working mechanism found! Aborting...\n"
else
    echo -e "\nFollowing mechanism(s) are working for public key retrieval.\nWhat do you want to use?\n  0) Abort/Quit"

    for index in "${!success[@]}"; do
        echo "  $((index+1))) ${success[$index]}"
    done

    echo ""
    read -r -p "Please, select by number: " choice
    echo ""


    number_regex='^[0-9]+$'
    if ! [[ ${choice} =~ ${number_regex} ]] || [[ ${choice} -gt ${#success[@]} ]]; then
        echo -e "Invalid choice! Aborting...\n"
        exit 1
    fi

    if [[ ${choice} -eq 0 ]]; then
        echo -e "Public key retrieval aborted!\n"
    else
        ((choice--))
        echo -e "Mechanism \"${success[$choice]}\" chosen...\n"

        if grep -q "@" <<<"$1"; then
            gpg --auto-key-locate "clear,${success[$choice]}" --locate-external-key "$1"
        else
            gpg --keyserver "${success[$choice]}" --recv-keys "$1"
        fi
    fi
fi
