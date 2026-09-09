# CV Curriculum — Teacher Setup Guide

This repository contains everything a teacher needs to outfit a classroom
of Raspberry Pi units for the Computer Vision Systems unit, starting from
a stock Raspberry Pi OS Bookworm (64-bit) image.

Unlike earlier pilot runs of this curriculum, this guide assumes you are
building the environment correctly from scratch — no need to fight with
NumPy/OpenCV/MediaPipe version conflicts, since this script installs
everything in the exact order and versions that avoid those issues.

## What You'll Need

- Raspberry Pi 4 or 5 (recommended: 4GB+ RAM)
- Official Raspberry Pi Camera Module (v2 or v3)
- microSD card (16GB minimum, 32GB+ recommended)
- Raspberry Pi Imager (installed on your computer)
- A monitor/keyboard for first boot, OR SSH access over your network

## Step 1: Image the SD Card

1. Open **Raspberry Pi Imager** on your computer.
2. Choose **Raspberry Pi OS (64-bit)** — the standard Bookworm desktop image.
3. Click the **gear icon** (OS customization) before writing:
   - Set a **unique hostname** for this Pi (e.g., `lhsengr01a`)
   - Set a **unique username and password**
   - Enable **SSH** (password authentication is fine for classroom use)
   - Optionally pre-configure Wi-Fi
4. Write the image to the SD card.
5. Insert the SD card into the Pi and boot it.

Repeat this for every physical Pi you're setting up — each one should get
its own hostname/username at this stage.

## Step 2: Connect and Run the Bootstrap Script

SSH into the Pi (or open a terminal if using a monitor/keyboard):

```bash
ssh <your-username>@<your-hostname>.local
```

Clone this repository (or copy `bootstrap_pi.sh` directly onto the Pi):

```bash
git clone https://github.com/YOUR_ORG/YOUR_TEACHER_REPO.git ~/setup
cd ~/setup
```

Run the bootstrap script:

```bash
bash bootstrap_pi.sh
```

This single script will:

1. Update the OS
2. Install and enable **RPi Connect** (this is NOT offered as an Imager
   customization option on Bookworm, so it must be installed manually)
3. Confirm the camera is detected (Bookworm auto-detects cameras — no
   manual "enable camera" step is needed, unlike older Raspberry Pi OS
   versions)
4. Install all system-level packages (OpenCV, Picamera2, camera libraries)
5. Create a Python virtual environment (`cv_env2`) with access to system
   packages
6. Install a pinned, compatible set of Python libraries:
   - `numpy` 1.25–1.x (avoids the NumPy 2.x ABI break that crashes OpenCV
     and Picamera2 binaries)
   - `mediapipe==0.10.18` (the version with the classic `mp.solutions.pose`
     API used throughout the curriculum)
   - `protobuf` 4.25.x (the version MediaPipe 0.10.18 actually needs)
   - `face_recognition`, `tflite-runtime`, and supporting libraries
7. Set `cv_env2` to auto-activate on every login
8. Optionally clone your class curriculum repo
9. Print a verification check of installed versions

## Step 3: Manual Steps (cannot be scripted)

A few steps require interactive input and can't be automated safely:

### a. Sign in to RPi Connect

```bash
rpi-connect signin
```

This will print a URL and a code — open the URL on any browser, sign in
with a Raspberry Pi account, and enter the code to link this specific Pi.

### b. Enable Wayland compositor + Desktop Autologin

This is required for RPi Connect's **screen sharing** feature to work
(without it, remote screen sharing will silently fail).

```bash
sudo raspi-config
```

- **Advanced Options → Wayland** → choose **Wayfire** (or **Labwc**)
- Back out to the main menu (do not exit yet)
- **System Options → Boot / Auto Login** → choose **Desktop Autologin**
- Exit and reboot when prompted

### c. Reboot and verify

```bash
sudo reboot
```

After reboot, SSH back in and confirm:

```bash
which python3
# should point to ~/Documents/scripts/cv_env2/bin/python3
```

Test the first lesson script:

```bash
python3 ~/Documents/scripts/pose_basic.py
```

## Step 4: Speeding Up Future Classroom Setups (Cloning)

Once you have ONE fully working Pi (a "golden image"), you can clone its
SD card to outfit additional Pis much faster than repeating Steps 1–3 from
scratch on every unit.

See `clone_setup.sh`, `cleanup_old_user.sh`, and `verify_setup.sh` in the
`clone-tools/` folder of this repo for the automated clone workflow,
including:
- Resetting machine-id and SSH host keys (prevents RPi Connect from
  confusing cloned Pis with the original)
- Creating a new user matching a new hostname
- Copying project files and fixing hardcoded virtual environment paths
- Safe deletion of the old user account

## Troubleshooting Reference

| Symptom | Cause | Fix |
|---|---|---|
| `ModuleNotFoundError: No module named 'picamera2'` | venv created without `--system-site-packages`, or picamera2 not installed via apt | Recreate venv with `--system-site-packages`; `sudo apt install python3-picamera2` |
| `numpy.dtype size changed` / `ValueError` on picamera2 import | numpy version mismatch between venv and system packages | Pin numpy to `<2.0` and `>=1.25` |
| `AttributeError: _ARRAY_API not found` | NumPy 2.x installed, breaking binaries compiled against NumPy 1.x | `pip install "numpy>=1.25,<2.0" --force-reinstall` |
| `ModuleNotFoundError: No module named 'google'` on mediapipe import | protobuf missing/wrong version | `pip install "protobuf>=4.25.3,<5" --force-reinstall` |
| RPi Connect shows wrong/old hostname for a cloned Pi | machine-id and SSH host keys were cloned along with the OS | Reset `/etc/machine-id` and `/etc/ssh/ssh_host_*`, then re-run `rpi-connect signin` |
| Screen sharing via RPi Connect doesn't work | Wayland compositor / desktop autologin not configured | `raspi-config` → Advanced Options → Wayland, then System Options → Boot/Auto Login → Desktop Autologin |
| `userdel: user X is currently used by process Y` | Old user still has an active session/process | `sudo pkill -u <user>` then retry `userdel -r` |
