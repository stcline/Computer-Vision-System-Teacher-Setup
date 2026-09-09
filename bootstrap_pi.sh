#!/bin/bash
# bootstrap_pi.sh
# Run this ONCE on a freshly imaged Raspberry Pi OS Bookworm (64-bit) card.
# Assumes hostname + username + password were already set via Raspberry Pi
# Imager's OS customization (gear icon) before first boot, and SSH was
# enabled there too.
#
# This script installs EVERYTHING needed for the CV curriculum in the
# correct order, avoiding every dependency conflict discovered during
# development (numpy/opencv/mediapipe ABI mismatches, protobuf version,
# picamera2 venv visibility, etc.)
#
# Usage: bash bootstrap_pi.sh

set -e

echo "=================================================="
echo " CV Curriculum Pi Bootstrap"
echo "=================================================="

echo ""
echo "=== Step 1: System update ==="
sudo apt update && sudo apt full-upgrade -y

echo ""
echo "=== Step 2: Install RPi Connect (not offered by Imager on Bookworm) ==="
sudo apt install -y rpi-connect
rpi-connect on
echo "NOTE: run 'rpi-connect signin' manually later to link this device (requires browser)."

echo ""
echo "=== Step 3: Verify camera (Bookworm auto-detects, no raspi-config toggle needed) ==="
rpicam-hello --list-cameras || echo "WARNING: no camera detected yet -- check ribbon cable seating."

echo ""
echo "=== Step 4: Install system-level packages ==="
sudo apt install -y \
  python3-full python3-venv python3-pip \
  python3-opencv python3-picamera2 \
  libatlas-base-dev libhdf5-dev libgtk-3-0 libcap-dev \
  libcamera-dev libkms++-dev libfmt-dev libdrm-dev ffmpeg git

echo ""
echo "=== Step 5: Create project directories ==="
mkdir -p ~/Documents/scripts
cd ~/Documents/scripts

echo ""
echo "=== Step 6: Create virtual environment (system-site-packages) ==="
python3 -m venv --system-site-packages cv_env2
source cv_env2/bin/activate

echo ""
echo "=== Step 7: Pin numpy to a 1.x version compatible with system OpenCV/Picamera2 AND Matplotlib ==="
pip install --upgrade pip wheel
pip install "numpy>=1.25,<2.0" --force-reinstall

echo ""
echo "=== Step 8: Install MediaPipe (pinned version, no-deps to avoid pulling in numpy 2 / duplicate opencv) ==="
pip install "mediapipe==0.10.18" --no-deps

echo ""
echo "=== Step 9: Install protobuf (correct version range for mediapipe 0.10.18) ==="
pip install "protobuf>=4.25.3,<5" --force-reinstall

echo ""
echo "=== Step 10: Install remaining mediapipe/matplotlib dependencies without upgrading numpy/opencv ==="
pip install absl-py flatbuffers sounddevice matplotlib --no-deps
pip install cffi pycparser contourpy cycler fonttools kiwisolver packaging pyparsing python-dateutil six

echo ""
echo "=== Step 11: Install remaining curriculum libraries ==="
pip install face_recognition tflite-runtime

echo ""
echo "=== Step 12: Auto-activate cv_env2 on every login ==="
if ! grep -q "cv_env2/bin/activate" ~/.bashrc; then
  echo "source ~/Documents/scripts/cv_env2/bin/activate" >> ~/.bashrc
fi

echo ""
echo "=== Step 13: Clone class repo ==="
read -p "Enter class repo URL (or press Enter to skip): " REPO_URL
if [ -n "$REPO_URL" ]; then
  git clone "$REPO_URL" ~/cv_project
fi

echo ""
echo "=== Step 14: Verify installation ==="
python3 -c "import numpy as np, cv2, mediapipe as mp; print('numpy', np.__version__, 'cv2', cv2.__version__, 'mediapipe', mp.__version__)"

echo ""
echo "=================================================="
echo " Automated steps complete!"
echo "=================================================="
echo "Remaining MANUAL steps (cannot be scripted):"
echo "  1. Run: rpi-connect signin        (requires browser-based device auth)"
echo "  2. Run: sudo raspi-config"
echo "       -> Advanced Options -> Wayland -> Wayfire (or Labwc)"
echo "       -> System Options -> Boot / Auto Login -> Desktop Autologin"
echo "     Then reboot."
echo "  3. After reboot, open a NEW terminal and confirm:"
echo "       which python3   (should point inside cv_env2)"
echo "  4. Test: python3 ~/Documents/scripts/pose_basic.py"
