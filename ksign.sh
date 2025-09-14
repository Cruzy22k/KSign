#!/bin/bash
set -euo pipefail
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
if ! command -v sbsign &>/dev/null; then
    echo "exception: sbsign is not installed. go install it from your package manager."
    exit 1
fi
if ! command -v sbverify &>/dev/null; then
    echo "exception: sbverify is not installed. usually in sbsigntools."
    exit 1
fi
if [ ! -f "$KEY" ] || [ ! -f "$CERT" ]; then
    echo "Error: key or cert not found at $KEY / $CERT"
    exit 1
fi
mapfile -t KERNELS < <(ls /boot/vmlinuz-* 2>/dev/null || true) 
if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No kernels found in /boot/"
    exit 1
fi

UNSIGNED_KERNELS=() # remove cur running kernel and check if signed.
for kernel in "${KERNELS[@]}"; do 
    [[ "$kernel" == "$CURRENT_VMLINUZ" ]] && continue
    if ! sbverify --list "$kernel" &>/dev/null; then
        UNSIGNED_KERNELS+=("$kernel")
    fi
done

if [ ${#UNSIGNED_KERNELS[@]} -eq 0 ]; then
    echo "no unsigned kernels found."
    exit 0
fi 

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