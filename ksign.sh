#!/bin/bash
set -euo pipefail
# Stop dumbasses writing to the currently running kernel
CURRENT_KERNEL=$(uname -r)
CURRENT_VMLINUZ="/boot/vmlinuz-$CURRENT_KERNEL"

# KSign kernel signing tool developed by Cruzy.


KEY="/root/mok/MOK.key"
CERT="/root/mok/MOK.crt"


KERNELS=($(ls /boot/vmlinuz-* 2>/dev/null))
if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No kernel images found in /boot/"
    exit 1
fi
# remove the runnin kernel
UNSIGNED_KERNELS=()
for kernel in "${KERNELS[@]}"; do
    if [ "$kernel" != "$CURRENT_VMLINUZ" ]; then
        UNSIGNED_KERNELS+=("$kernel")
    fi
done


PS3="Select a kernel to sign: "
select kernel in "${UNSIGNED_KERNELS[@]}"; do
    if [ -n "$kernel" ]; then
        echo "Signing $kernel..."
        sudo sbsign --key "$KEY" --cert "$CERT" --output "$kernel.signed" "$kernel"
        echo "Signed kernel saved as $kernel.signed"
        break
    else
        echo "Invalid"
    fi
done
