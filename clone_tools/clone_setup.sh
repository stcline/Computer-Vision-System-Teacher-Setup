#!/bin/bash
# clone_setup.sh
# Run this ONCE after booting a freshly cloned SD card, logged in as the OLD user.
# Usage: sudo bash clone_setup.sh <OLD_USERNAME> <NEW_USERNAME> <NEW_HOSTNAME>
#
# This script handles everything EXCEPT:
#   - Setting the new user's password (adduser will prompt you)
#   - raspi-config Wayland/Autologin menus (must be done interactively)
#   - RPi Connect sign-in (requires browser-based auth)
# Run finish_setup.sh (part 2) for those remaining steps.

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo bash clone_setup.sh <OLD_USERNAME> <NEW_USERNAME> <NEW_HOSTNAME>"
  exit 1
fi

if [ $# -ne 3 ]; then
  echo "Usage: sudo bash clone_setup.sh <OLD_USERNAME> <NEW_USERNAME> <NEW_HOSTNAME>"
  exit 1
fi

OLD_USERNAME="$1"
NEW_USERNAME="$2"
NEW_HOSTNAME="$3"

echo "=== Step 1: Resetting machine identity ==="
rm -f /etc/machine-id
systemd-machine-id-setup

rm -f /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

rm -f /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

echo "=== Step 2: Setting hostname to $NEW_HOSTNAME ==="
raspi-config nonint do_hostname "$NEW_HOSTNAME"

echo "=== Step 3: Creating new user $NEW_USERNAME ==="
echo "You will be prompted to set a password for $NEW_USERNAME."
adduser "$NEW_USERNAME"

echo "=== Step 4: Copying group memberships from $OLD_USERNAME ==="
usermod -a -G "$(groups "$OLD_USERNAME" | cut -d: -f2 | xargs | tr ' ' ',')" "$NEW_USERNAME"

echo "=== Step 5: Copying project files (includes scripts/pose_basic.py) ==="
cp -r "/home/$OLD_USERNAME/Documents" "/home/$NEW_USERNAME/"
chown -R "$NEW_USERNAME:$NEW_USERNAME" "/home/$NEW_USERNAME/Documents"

echo "=== Step 6: Fixing hardcoded venv paths ==="
VENV_DIR="/home/$NEW_USERNAME/Documents/scripts/cv_env2"
for f in "$VENV_DIR/bin/activate" "$VENV_DIR/pyvenv.cfg" "$VENV_DIR/bin/pip" "$VENV_DIR/bin/pip3"; do
  if [ -f "$f" ]; then
    sed -i "s|/home/$OLD_USERNAME/|/home/$NEW_USERNAME/|g" "$f"
  fi
done

echo "=== Step 7: Auto-activating cv_env2 for $NEW_USERNAME ==="
NEW_BASHRC="/home/$NEW_USERNAME/.bashrc"
if ! grep -q "cv_env2/bin/activate" "$NEW_BASHRC"; then
  echo "source ~/Documents/scripts/cv_env2/bin/activate" >> "$NEW_BASHRC"
fi
chown "$NEW_USERNAME:$NEW_USERNAME" "$NEW_BASHRC"

echo ""
echo "=== Automated steps complete! ==="
echo "Old user '$OLD_USERNAME' was NOT deleted yet."
echo "Next steps:"
echo "  1. Reboot: sudo reboot"
echo "  2. SSH back in as $NEW_USERNAME@$NEW_HOSTNAME"
echo "  3. Once confirmed working, run: sudo bash cleanup_old_user.sh $OLD_USERNAME"
echo "  4. Run finish_setup.sh for the interactive raspi-config + RPi Connect steps"
