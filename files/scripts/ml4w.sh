#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Get latest tag from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Check if package is installed
_isInstalled() {
    package="$1";
    check=$(rpm -qa | grep $package)
    if [ -z "$check" ]; then
        echo 1; #'1' means 'false' in Bash
        return; #false
    else
        echo 0; #'0' means 'true' in Bash
        return; #true
    fi
}

# Install required packages
_installPackages() {
    toInstall=();
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo "${pkg} is already installed.";
            continue;
        fi;
        toInstall+=("${pkg}");
    done;
    if [[ "${toInstall[@]}" == "" ]] ; then
        return;
    fi;
    printf "Package not installed:\n%s\n" "${toInstall[@]}";
    rpm-ostree install --assumeyes "${toInstall[@]}"
}

# Required packages for the installer
packages=(
    "wget"
    "unzip"
    "rsync"
    "git"
    "figlet"
)

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

echo ":: Starting automated installation..."

# Create Downloads folder if not exists
if [ ! -d ~/Downloads ]; then
    mkdir ~/Downloads
    echo ":: Downloads folder created"
fi 

# Remove existing download folder and zip files 
if [ -f $HOME/Downloads/dotfiles-main.zip ]; then
    rm $HOME/Downloads/dotfiles-main.zip
fi
if [ -f $HOME/Downloads/dotfiles-dev.zip ]; then
    rm $HOME/Downloads/dotfiles-dev.zip
fi
if [ -f $HOME/Downloads/dotfiles.zip ]; then
    rm $HOME/Downloads/dotfiles.zip
fi
if [ -d $HOME/Downloads/dotfiles ]; then
    rm -rf $HOME/Downloads/dotfiles
fi
if [ -d $HOME/Downloads/dotfiles_temp ]; then
    rm -rf $HOME/Downloads/dotfiles_temp
fi
if [ -d $HOME/Downloads/dotfiles-main ]; then
    rm -rf $HOME/Downloads/dotfiles-main
fi
if [ -d $HOME/Downloads/dotfiles-dev ]; then
    rm -rf $HOME/Downloads/dotfiles-dev
fi

# Install required packages
echo ":: Installing required packages..."
_installPackages "${packages[@]}";

# Try to install gum but continue if it fails
rpm-ostree install --assumeyes gum || true

echo ":: Installing Main Release"
git clone --branch $latest_version --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles

echo ":: Download complete."
echo

# Cd into dotfiles folder
cd $HOME/Downloads/dotfiles/bin/

# Start Spinner (continue if it fails)
gum spin --spinner dot --title "Starting the installation now..." -- sleep 3 || echo ":: Starting the installation..."

# Start installation
./ml4w-hyprland-setup -m install
echo

# Start Spinner (continue if it fails)
gum spin --spinner dot --title "Starting the setup now..." -- sleep 3 || echo ":: Starting the setup..."

# Start setup
./ml4w-hyprland-setup -p fedora
