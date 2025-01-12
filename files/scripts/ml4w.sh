#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Get latest tag from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Get latest zip from GitHub
get_latest_zip() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" | # Get latest release from GitHub api
    grep '"zipball_url":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

# Check if package is installed
_isInstalled() {
    package="$1";
    check=$(rpm -q "$package" 2>/dev/null)
    if [ -z "$check" ]; then
        echo 1; # '1' means 'false' in Bash
        return; # false
    else
        echo 0; # '0' means 'true' in Bash
        return; # true
    fi
}

# Install required packages non-interactively
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
    printf "Package(s) not installed:\n%s\n" "${toInstall[@]}";
    sudo rpm-ostree install --assumeyes "${toInstall[@]}"
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

# Automatically proceed with the installation without user interaction
echo ":: Installation started"
echo

# Create Downloads folder if not exists
if [ ! -d ~/Downloads ]; then
    mkdir ~/Downloads
    echo ":: Downloads folder created"
fi 

# Remove existing download folder and zip files 
rm -f $HOME/Downloads/dotfiles-main.zip
rm -f $HOME/Downloads/dotfiles-dev.zip
rm -f $HOME/Downloads/dotfiles.zip
rm -rf $HOME/Downloads/dotfiles
rm -rf $HOME/Downloads/dotfiles_temp
rm -rf $HOME/Downloads/dotfiles-main
rm -rf $HOME/Downloads/dotfiles-dev

# Install required packages
echo ":: Checking that required packages are installed..."
_installPackages "${packages[@]}";

bash <(curl -s https://raw.githubusercontent.com/mylinuxforwork/dotfiles/main/share/packages/fedora/special/gum.sh)

echo
# Select the dotfiles version (automatically choose "main-release")
version="main-release"
echo ":: Automatically selecting main-release"

# Download the chosen version
if [ "$version" == "main-release" ]; then
    echo ":: Installing Main Release"
    echo
    git clone --branch $latest_version --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles
elif [ "$version" == "rolling-release" ]; then
    echo ":: Installing Rolling Release"
    echo
    git clone --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles
else
    echo ":: Setup canceled"
    exit 130
fi
echo ":: Download complete."
echo
# Cd into dotfiles folder
cd $HOME/Downloads/dotfiles/bin/

# Start Spinner (automatically wait)
gum spin --spinner dot --title "Starting the installation now..." -- sleep 3

# Use expect to handle prompts
expect << EOF
spawn ./ml4w-hyprland-setup -m install
expect {
    "Do you want to continue? (Y/N)" { send "Y\r"; exp_continue }
    "Are you sure?" { send "Y\r"; exp_continue }
    eof
}
EOF
echo

# Start Spinner (automatically wait)
gum spin --spinner dot --title "Starting the setup now..." -- sleep 3

# Use expect to handle prompts during setup
expect << EOF
spawn ./ml4w-hyprland-setup -p fedora
expect {
    "Do you want to continue? (Y/N)" { send "Y\r"; exp_continue }
    "Are you sure?" { send "Y\r"; exp_continue }
    eof
}
EOF
