#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Get latest release
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Required packages for the installer
packages=("wget" "unzip" "rsync" "git" "figlet" "gum")

# Check and install required packages
sudo dnf install --assumeyes "${packages[@]}"

# Predefine responses
yn="Y"  # Auto-confirm installation
version="main-release"  # Default version

# Create Downloads folder
mkdir -p ~/Downloads

# Clean up old files
rm -rf ~/Downloads/dotfiles ~/Downloads/dotfiles_temp ~/Downloads/dotfiles-main ~/Downloads/dotfiles-dev
rm -f ~/Downloads/dotfiles*.zip

# Clone appropriate dotfiles version
if [ "$version" == "main-release" ]; then
  git clone --branch $(get_latest_release) --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles
else
  git clone --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles
fi

# Navigate to the bin directory
cd ~/Downloads/dotfiles/bin/

# Run the installation and setup
./ml4w-hyprland-setup -m install
./ml4w-hyprland-setup -p fedora
