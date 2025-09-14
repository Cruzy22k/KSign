#!/bin/bash
set -euo pipefail

GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}<KSign>  Copyleft (C) 2024  Cruzy22k${RESET}"
echo -e "${GREEN}This program comes with ABSOLUTELY NO WARRANTY.${RESET}"
echo -e "${GREEN}This is free software, and you are welcome to redistribute it under certain conditions.${RESET}"
echo
echo "dont sign rescue kernels, i am not sure what that might do."
usage() {
    cat <<EOF
Usage: $0 [OPTION]

Options:
  -a      auto sign every kernel in /boot (cron-friendly)
  -h      show help
  -c      credits
  -k      specify key file (default: /root/mok/MOK.key)
  -t      specify cert file (default: /root/mok/MOK.crt)
Description:
  KSign is a universal kernel signing tool.
  Automatically signs new kernels for Secure Boot.
EOF
}

creds() {
    echo "Made with <3 by Cruzy"
}

KEY="/root/mok/MOK.key" # adjustable but probably best to use /root/mok
CERT="/root/mok/MOK.crt"

while getopts "ahck:t:" opt; do
    case $opt in
        a) AUTO=1 ;;
        h) usage; exit 0 ;;
        c) creds; exit 0 ;;
        k) KEY="$OPTARG" ;;
        t) CERT="$OPTARG" ;;
        *) usage; exit 1 ;;
    esac
done # case esta mejor

CURRENT_KERNEL=$(uname -r) # stop dumbasses flshing cur kern
CURRENT_VMLINUZ="/boot/vmlinuz-$CURRENT_KERNEL" # set

# check dependencies
for cmd in sbsign sbverify; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "exception: $cmd is not installed. go install it"
        exit 1
    fi
done
if [ ! -f "$KEY" ] || [ ! -f "$CERT" ]; then
    echo "exception: key or cert not found at $KEY / $CERT" 
    echo "Instructions are at the bottome of the readme."
    exit 1
fi

mapfile -t KERNELS < <(ls /boot/vmlinuz-* 2>/dev/null || true)
if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No kernels found in /boot/" # should'nt really happen but edge case
    exit 0
fi

# remove currently running kernel from list
UNSIGNED_KERNELS=()
for kernel in "${KERNELS[@]}"; do
    [[ "$kernel" == "$CURRENT_VMLINUZ" ]] && continue
    UNSIGNED_KERNELS+=("$kernel")
done

if [ ${#UNSIGNED_KERNELS[@]} -eq 0 ]; then
    echo "No kernels to sign (only running kernel present)."
    exit 0
fi

# auto mode
if [[ "${AUTO:-}" == "1" ]]; then
    echo "Auto-signing kernels in /boot..."
    for kernel in "${UNSIGNED_KERNELS[@]}"; do
        tmpfile="${kernel}.signed"
        echo "Signing $kernel..."
        sbsign --key "$KEY" --cert "$CERT" --output "$tmpfile" "$kernel"
        mv "$tmpfile" "$kernel"
        echo "Signed $kernel successfully."
    done
    exit 0
fi

# interactive mode
PS3="Select a kernel to sign: "
select kernel in "${UNSIGNED_KERNELS[@]}"; do
    if [ -n "$kernel" ]; then
        echo "Signing $kernel..."
        tmpfile="${kernel}.signed"
        sbsign --key "$KEY" --cert "$CERT" --output "$tmpfile" "$kernel"
        mv "$tmpfile" "$kernel"
        echo "Signed $kernel successfully."
        break
    else
        echo "invalid selection."
    fi
done
