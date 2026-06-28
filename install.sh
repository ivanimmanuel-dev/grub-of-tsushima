#!/bin/bash

set -euo pipefail

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g. sudo ./install.sh)"
  exit 1
fi

echo "============================================"
echo "      Grub of Tsushima Theme Installer"
echo "============================================"
echo ""

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Step 1: Select Variant
echo "Please select the variant you want to install:"
echo "1) Ghost of Tsushima - White (Clean, minimal, faithful to the game)"
echo "2) Ghost of Tsushima - Black (Original version with icons)"
echo "3) Cancel installation"
echo ""

read -r -p "Enter your choice [1-3]: " choice

case $choice in
    1)
        THEME_DIR="grub-of-tsushima-white"
        ;;
    2)
        THEME_DIR="grub-of-tsushima-black"
        ;;
    3)
        echo "Installation cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Directory $THEME_DIR not found. Are you running this script from the theme's directory?"
    exit 1
fi

echo ""
echo "Selected variant: $THEME_DIR"
echo ""

# Step 2: Check and backup GRUB configuration
echo "Step 1: Checking /etc/default/grub..."

if [ ! -f /etc/default/grub ]; then
    echo "Error: /etc/default/grub does not exist."
    exit 1
fi

# Backup the original config if backup doesn't exist
if [ ! -f /etc/default/grub.bak ]; then
    echo "  -> Creating backup at /etc/default/grub.bak"
    cp /etc/default/grub /etc/default/grub.bak
fi

# Step 3: Copy files
if [ -d "/boot/grub2/themes" ] || [ -d "/boot/grub2" ]; then
    GRUB_DIR="/boot/grub2"
else
    GRUB_DIR="/boot/grub"
fi
THEME_DEST="${GRUB_DIR}/themes/grub-of-tsushima"

echo "Step 2: Creating GRUB themes directory if it doesn't exist..."
mkdir -p "${GRUB_DIR}/themes"

echo "Step 3: Copying theme files to $THEME_DEST..."
if [ -d "$THEME_DEST" ]; then
    echo -n "Theme directory $THEME_DEST already exists. Do you want to overwrite it? [y/N]: "
    read -r confirm
    if [[ "$confirm" != [yY] && "$confirm" != [yY][eE][sS] ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    echo "  -> Removing old theme files..."
    rm -rf "$THEME_DEST"
fi
cp -r "$THEME_DIR" "$THEME_DEST"

# Step 4: Update GRUB configuration
echo "Step 4: Updating /etc/default/grub..."

# Remove existing GRUB_THEME lines
sed -i '/^GRUB_THEME=/d' /etc/default/grub
# Append new theme config
cat <<EOF >> /etc/default/grub
GRUB_THEME="${THEME_DEST}/theme.txt"
EOF

# Disable console output if enabled (it breaks graphical themes)
sed -i 's/^\(GRUB_TERMINAL_OUTPUT="console"\)/#\1/' /etc/default/grub

# Step 5: Update GRUB
echo "Step 5: Updating GRUB bootloader..."

UPDATE_SUCCESS=true

if command -v update-grub &> /dev/null; then
    update-grub
elif [ "$GRUB_DIR" = "/boot/grub2" ] && command -v grub2-mkconfig &> /dev/null; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
elif [ "$GRUB_DIR" = "/boot/grub" ] && command -v grub-mkconfig &> /dev/null; then
    grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "Warning: Could not find a command to update GRUB."
    echo "Please update GRUB manually."
    UPDATE_SUCCESS=false
fi

echo ""
echo "============================================"
if [ "$UPDATE_SUCCESS" = true ]; then
    echo "           Installation Complete!"
else
    echo " Theme installed, but manual GRUB update needed!"
fi
echo "============================================"
echo ""
