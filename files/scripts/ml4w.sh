#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Get latest tag from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Install required packages
_installPackages() {
    toInstall=();
    for pkg; do
        if ! rpm -q $pkg &>/dev/null; then
            toInstall+=("${pkg}");
        fi;
    done;
    if [[ "${toInstall[@]}" == "" ]] ; then
        return;
    fi;
    sudo dnf install --assumeyes "${toInstall[@]}"
}

# Required packages for the installer
packages=("wget" "unzip" "rsync" "git" "figlet")

latest_version=$(get_latest_release)

# Some colors
GREEN='\033[0;32m'
NONE='\033[0m'

# Header
echo -e "${GREEN}"
cat <<"EOF"
   ____         __       ____       
  /  _/__  ___ / /____ _/ / /__ ____
 _/ // _ \(_-</ __/ _ `/ / / -_) __/
/___/_//_/___/\__/\_,_/_/_/\__/_/   
                                    
EOF
echo "ML4W Dotfiles for Hyprland"
echo -e "${NONE}"

# Automatically start installation without asking
echo ":: Installation started"
echo

# Create Downloads folder if not exists
mkdir -p ~/Downloads

# Clean up old files
rm -rf ~/Downloads/dotfiles ~/Downloads/dotfiles_temp ~/Downloads/dotfiles-main ~/Downloads/dotfiles-dev
rm -f ~/Downloads/dotfiles*.zip

# Install required packages
echo ":: Checking that required packages are installed..."
_installPackages "${packages[@]}";

bash <(curl -s https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/share/packages/fedora/special/gum.sh)

# Clone the main release of the dotfiles repo
echo ":: Cloning the main release of the dotfiles repository"
git clone --branch $latest_version --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles

echo ":: Download complete."
echo

# Cd into dotfiles folder
cd $HOME/Downloads/dotfiles/bin/

# Start installation
gum spin --spinner dot --title "Starting the installation now..." -- sleep 3
./ml4w-hyprland-setup -m install
echo

# Start setup
gum spin --spinner dot --title "Starting the setup now..." -- sleep 3
./ml4w-hyprland-setup -p fedora
