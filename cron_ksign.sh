#!/bin/bash
set -euo pipefail
# KSign cron job script simple version.
# Just signs any unsigned kernels in /boot except the currently running one.
KEY="/root/mok/MOK.key"
CERT="/root/mok/MOK.crt"
LOGFILE="/var/log/ksign.log"

CURRENT_KERNEL=$(uname -r) # stop dumbasses writing to the currently running kernel
CURRENT_VMLINUZ="/boot/vmlinuz-$CURRENT_KERNEL"

for kernel in /boot/vmlinuz-*; do
    [[ "$kernel" == "$CURRENT_VMLINUZ" ]] && continue
    if ! sbverify --list "$kernel" &>/dev/null; then
        tmpfile="${kernel}.signed"
        sbsign --key "$KEY" --cert "$CERT" --output "$tmpfile" "$kernel"
        if sbverify --list "$tmpfile" &>/dev/null; then
            mv "$tmpfile" "$kernel"
            echo "$(date): Signed $kernel successfully" >> "$LOGFILE"
        else
            echo "$(date): verif failed for $kernel" >> "$LOGFILE"
            rm -f "$tmpfile"
        fi
    fi
done
