#!/usr/bin/env bash
set -euo pipefail

# fix_cgroup.sh
# Ensure kernel boot parameters enable memory cgroup accounting (and fallback to cgroup v1)
# Usage: sudo ./scripts/fix_cgroup.sh [--reboot]

REBOOT=false
if [ "${1:-}" = "--reboot" ] || [ "${1:-}" = "-r" ]; then
  REBOOT=true
fi

GRUB_FILE="/etc/default/grub"
BACKUP="${GRUB_FILE}.bak.$(date +%Y%m%d%H%M%S)"

echo "This script will modify ${GRUB_FILE} to enable memory cgroup accounting and update grub."
echo "A backup will be written to: ${BACKUP}"

if [ ! -w "$GRUB_FILE" ]; then
  echo "This script needs to be run with sudo/root to modify ${GRUB_FILE}." >&2
  exit 1
fi

cp "$GRUB_FILE" "$BACKUP"

# Desired flags
BASE_FLAGS="cgroup_enable=memory swapaccount=1"
# When distro uses cgroup v2 by default, we want to add this to force v1
CGROUP_V1_FLAG="systemd.unified_cgroup_hierarchy=0"

# Read current GRUB_CMDLINE_LINUX_DEFAULT
CURRENT_LINE=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE" || true)
if [ -z "$CURRENT_LINE" ]; then
  echo "GRUB_CMDLINE_LINUX_DEFAULT not found in $GRUB_FILE; adding it." \
    >> "$GRUB_FILE"
  CURRENT_LINE="GRUB_CMDLINE_LINUX_DEFAULT=\"\""
fi

# Helper to inject a flag if not present
inject_flag() {
  local flag="$1"
  if ! grep -q "$flag" "$GRUB_FILE"; then
    echo "Adding flag: $flag"
    # Use sed to append the flag inside the quotes of GRUB_CMDLINE_LINUX_DEFAULT
    sed -i \
      -E \
      "s#^(GRUB_CMDLINE_LINUX_DEFAULT=\")([^"]*)(\"")?#\1\2 $flag\3#" \
      "$GRUB_FILE"
  else
    echo "Flag already present: $flag"
  fi
}

inject_flag "$BASE_FLAGS"
inject_flag "$CGROUP_V1_FLAG"

echo "Updated $GRUB_FILE. Running grub update..."

# Try common update commands
if command -v update-grub >/dev/null 2>&1; then
  update-grub
elif command -v grub-mkconfig >/dev/null 2>&1 && [ -d /boot/grub ]; then
  grub-mkconfig -o /boot/grub/grub.cfg
elif command -v grub2-mkconfig >/dev/null 2>&1 && [ -d /boot/grub2 ]; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
else
  echo "Could not find a grub update command. Please run 'update-grub' or equivalent manually." >&2
  exit 1
fi

echo "Grub updated. You must reboot for changes to take effect."
if [ "$REBOOT" = true ]; then
  echo "Rebooting now..."
  exec sudo reboot
fi

echo "Done. Reboot when convenient to apply kernel parameters."
