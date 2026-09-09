#!/bin/bash
# verify_setup.sh
# Run this as the NEW user after reboot to confirm everything is working.
# Usage: bash verify_setup.sh

echo "=== Checking virtual environment ==="
echo "VIRTUAL_ENV = $VIRTUAL_ENV"
which python3

echo ""
echo "=== Checking package versions ==="
python3 -c "import numpy as np, cv2, mediapipe as mp; print('numpy', np.__version__, 'cv2', cv2.__version__, 'mediapipe', mp.__version__)"

echo ""
echo "=== Checking camera ==="
rpicam-hello --list-cameras

echo ""
echo "=== Checking hostname ==="
hostnamectl

echo ""
echo "If all of the above look correct, run: python3 ~/Documents/scripts/pose_basic.py"
