#!/bin/bash
set -euo pipefail

GREEN="\e[32m"
RESET="\e[0m"

echo -e "${GREEN}<KSign>  Copyleft (C) 2024  Cruzy22k${RESET}"
echo -e "${GREEN}This program comes with ABSOLUTELY NO WARRANTY.${RESET}"
echo -e "${GREEN}This is free software, and you are welcome to redistribute it under certain conditions.${RESET}"
echo


usage() {
    cat <<EOF
Usage: $0 [OPTION]

Options:
  -a      auto sign every kernel for crontab or smt
  -h      show help
  -c      credits
Description:
  KSign is a kernel signing tool.
  useful if you run a custom kernel like Cachyos but want Secure boot to be enabled, and 
  want to automate the signing of each new kernel as it releases.
EOF
}
creds(){
    echo "Made with <3 by Cruzy"
}

# Stop dumbasses writing to the currently running kernel
CURRENT_KERNEL=$(uname -r)
CURRENT_VMLINUZ="/boot/vmlinuz-$CURRENT_KERNEL"
KEY="/root/mok/MOK.key"
CERT="/root/mok/MOK.crt"

# KSign kernel signing tool developed by Cruzy.

if [[ "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi
if [[ "${1:-}" == "-c" ]]; then
    creds
    exit 0
fi

# checks
for cmd in sbsign sbverify; do      # loop esta mejor                      
    if ! command -v "$cmd" &>/dev/null; then
        echo "exception: $cmd is not installed. install it from your package manager."
        exit 1
    fi
done
if [ ! -f "$KEY" ] || [ ! -f "$CERT" ]; then
    echo "Error: key or cert not found at $KEY / $CERT"
    exit 1
fi
mapfile -t KERNELS < <(ls /boot/vmlinuz-* 2>/dev/null || true) 
if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No kernels found in /boot/"
    exit 1
fi


for kernel in "${KERNELS[@]}"; do
    [[ "$kernel" == "$CURRENT_VMLINUZ" ]] && continue # remove cur
    if sbverify --list "$kernel" 2>&1 | grep -q "signature"; then
        # Already signed
        continue
    else
        UNSIGNED_KERNELS+=("$kernel")
    fi
done


if [[ "${1:-}" == "-a" ]]; then # -a
    echo "auto mode for running as like a cronjob or something."
    for kernel in "${UNSIGNED_KERNELS[@]}"; do
        tmpfile="${kernel}.signed"
        sbsign --key "$KEY" --cert "$CERT" --output "$tmpfile" "$kernel"
        if sbverify --list "$tmpfile" &>/dev/null; then
            mv "$tmpfile" "$kernel"
            echo "Signed $kernel successfully"
        else
            echo "Verification failed for $kernel"
            rm -f "$tmpfile"
        fi
    done
    exit 0
fi

PS3="Select a kernel to sign: "
select kernel in "${UNSIGNED_KERNELS[@]}"; do
    if [ -n "$kernel" ]; then
        echo "Signing $kernel..."
        tmpfile="${kernel}.signed"
        sbsign --key "$KEY" --cert "$CERT" --output "$tmpfile" "$kernel"
        echo "Verifying signature..."
        if sbverify --list "$tmpfile" &>/dev/null; then
            mv "$tmpfile" "$kernel"
            echo "Signed $kernel successfully"
        else
            echo "Verification failed, leaving original untouched"
            rm -f "$tmpfile"
        fi
        break
    else
        echo "invalid selection."
    fi
done
