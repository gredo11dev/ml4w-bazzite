#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Debugging: Display current working directory and list files
echo "Current directory: $(pwd)"
echo "Files in current directory: $(ls -l)"

# Get latest release
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" |
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Required packages for the installer
packages=("wget" "unzip" "rsync" "git" "figlet" "gum")

# Check and install required packages
echo "Installing required packages..."
sudo dnf install --assumeyes "${packages[@]}"

# Predefine responses
yn="Y"  # Auto-confirm installation
version="main-release"  # Default version

# Create Downloads folder
mkdir -p ~/Downloads

# Clean up old files
echo "Cleaning up old files..."
rm -rf ~/Downloads/dotfiles ~/Downloads/dotfiles_temp ~/Downloads/dotfiles-main ~/Downloads/dotfiles-dev
rm -f ~/Downloads/dotfiles*.zip

# Clone appropriate dotfiles version
echo "Cloning dotfiles repository..."
if [ "$version" == "main-release" ]; then
  git clone --branch $(get_latest_release) --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles
else
  git clone --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles
fi

# Navigate to the bin directory
cd ~/Downloads/dotfiles/bin/

# Ensure that the script is executable (in case it's not)
echo "Ensuring script is executable..."
chmod +x ml4w-hyprland-setup

# Run the installation and setup
echo "Running Hyprland setup..."
./ml4w-hyprland-setup -m install
./ml4w-hyprland-setup -p fedora

# Final debugging step: List the files in the current directory after execution
echo "Listing files in ~/Downloads/dotfiles/bin/:"
ls -l ~/Downloads/dotfiles/bin/
