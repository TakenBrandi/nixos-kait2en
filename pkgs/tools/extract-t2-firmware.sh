#!/usr/bin/env bash
# Extract Apple Broadcom Wi-Fi and Bluetooth firmware from macOS partition or USB
set -euo pipefail

TARGET_DIR="${1:-./firmware}"
SOURCE_DIR="${2:-}"

echo "=== Apple T2 Firmware Extractor for NixOS ==="

if [[ -z "$SOURCE_DIR" ]]; then
  # Search common mount points and directories
  for candidate in /mnt/macos /mnt /run/media/*/* /Volumes/* /boot/EFI/apple-firmware /boot/efi/apple-firmware ./apple-firmware; do
    if [[ -d "$candidate/usr/share/firmware/wifi" || -d "$candidate/wifi" ]]; then
      SOURCE_DIR="$candidate"
      break
    fi
  done
fi

if [[ -z "$SOURCE_DIR" || ! -d "$SOURCE_DIR" ]]; then
  echo "Error: Could not locate macOS firmware files in standard locations."
  echo ""
  echo "Usage: $0 [OUTPUT_DIRECTORY] [SOURCE_DIRECTORY]"
  echo ""
  echo "Ways to supply firmware:"
  echo "  1) If you copied 'wifi' and 'bluetooth' from macOS to USB or EFI:"
  echo "     $0 /lib/firmware/brcm /path/to/copied/firmware"
  echo ""
  echo "  2) If your macOS APFS partition is not encrypted with FileVault:"
  echo "     sudo mkdir -p /mnt/macos"
  echo "     sudo apfs-fuse -o allow_other /dev/nvme0n1p2 /mnt/macos"
  echo "     $0 /lib/firmware/brcm /mnt/macos"
  echo ""
  exit 1
fi

echo "Found firmware source at: $SOURCE_DIR"
mkdir -p "$TARGET_DIR"

# 1. Wi-Fi Firmware (BCM4364 / BCM4355 / BCM4377)
WIFI_SRC=""
if [[ -d "$SOURCE_DIR/usr/share/firmware/wifi" ]]; then
  WIFI_SRC="$SOURCE_DIR/usr/share/firmware/wifi"
elif [[ -d "$SOURCE_DIR/wifi" ]]; then
  WIFI_SRC="$SOURCE_DIR/wifi"
fi

if [[ -n "$WIFI_SRC" && -d "$WIFI_SRC" ]]; then
  echo "Extracting Wi-Fi firmware from $WIFI_SRC..."
  find "$WIFI_SRC" -type f \( -name "C-4364*.*" -o -name "*4364*.*" -o -name "brcmfmac*" \) | while read -r f; do
    base=$(basename "$f")
    cp -v "$f" "$TARGET_DIR/$base" 2>/dev/null || true
  done
fi

# 2. Bluetooth Firmware (.hcd files)
BT_SRC=""
if [[ -d "$SOURCE_DIR/usr/share/firmware/bluetooth" ]]; then
  BT_SRC="$SOURCE_DIR/usr/share/firmware/bluetooth"
elif [[ -d "$SOURCE_DIR/bluetooth" ]]; then
  BT_SRC="$SOURCE_DIR/bluetooth"
fi

if [[ -n "$BT_SRC" && -d "$BT_SRC" ]]; then
  echo "Extracting Bluetooth firmware from $BT_SRC..."
  find "$BT_SRC" -type f \( -name "*4364*.hcd" -o -name "BCM*.hcd" \) | while read -r f; do
    base=$(basename "$f")
    cp -v "$f" "$TARGET_DIR/$base" 2>/dev/null || true
  done
fi

echo "Extraction complete! Files placed in: $TARGET_DIR"
echo "To reload Wi-Fi driver:"
echo "  sudo modprobe -r brcmfmac && sudo modprobe brcmfmac"
