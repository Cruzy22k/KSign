#!/bin/bash
set -euo pipefail
# KSign cron job script made way more simple.
# Signs any unsigned kernels in /boot except the currently running one.

KEY="/root/mok/MOK.key"
CERT="/root/mok/MOK.crt"
LOGFILE="/var/log/ksign.log"
LASTRUN_FILE="/var/log/ksign.last"

# Skip if already ran today
if [[ -f "$LASTRUN_FILE" ]]; then
    LASTRUN=$(date -r "$LASTRUN_FILE" +%Y-%m-%d)
    TODAY=$(date +%Y-%m-%d)
    [[ "$LASTRUN" == "$TODAY" ]] && exit 0
fi

CURRENT_KERNEL=$(uname -r) 
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
            echo "$(date): Verification failed for $kernel" >> "$LOGFILE"
            rm -f "$tmpfile"
        fi
    fi
done
touch "$LASTRUN_FILE"