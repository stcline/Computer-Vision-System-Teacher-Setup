#!/bin/bash
# cleanup_old_user.sh
# Run this AFTER confirming the new user works correctly.
# Usage: sudo bash cleanup_old_user.sh <OLD_USERNAME>

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo bash cleanup_old_user.sh <OLD_USERNAME>"
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: sudo bash cleanup_old_user.sh <OLD_USERNAME>"
  exit 1
fi

OLD_USERNAME="$1"

echo "=== Checking for active sessions/processes for $OLD_USERNAME ==="
who | grep "$OLD_USERNAME" || echo "No active login sessions found."

echo "=== Killing any remaining processes owned by $OLD_USERNAME ==="
pkill -u "$OLD_USERNAME" 2>/dev/null || echo "No processes to kill."

sleep 2

echo "=== Deleting user $OLD_USERNAME and home directory ==="
userdel -r "$OLD_USERNAME"

echo "Done. User $OLD_USERNAME has been removed."
