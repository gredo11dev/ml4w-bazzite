#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Get latest tag from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" | 
    grep '"tag_name":' | 
    sed -E 's/.*"([^"]+)".*/\1/'
}

# Check if package is installed
_isInstalled() {
    package="$1"
    check=$(yum list installed | grep $package)
    if [ -z "$check" ]; then
        echo 1
        return 1  # false
    else
        echo 0
        return 0  # true
    fi
}

# Install required packages
_installPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo "${pkg} is already installed."
            continue
        fi
        toInstall+=("${pkg}")
    done
    if [[ "${toInstall[@]}" == "" ]]; then
        return
    fi
    printf "Package not installed:\n%s\n" "${toInstall[@]}"
    sudo -n dnf install --assumeyes "${toInstall[@]}"
}

# Install Gum if not installed
install_gum() {
    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo -n tee /etc/yum.repos.d/charm.repo
    sudo -n yum install --assumeyes gum
}

# Install Expect if not installed
install_expect() {
    if ! command -v expect &>/dev/null; then
        echo ":: Installing expect..."
        sudo -n dnf install --assumeyes expect
    fi
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

# Install required packages and gum
echo ":: Checking and installing required packages..."
_installPackages "${packages[@]}"
install_gum
install_expect

# Automatically clone the "main-release" without interaction
echo ":: Automatically installing Main Release"

# Clone the main release directly without any prompts
git clone --branch $latest_version --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles

echo ":: Download complete."
echo

# Cd into dotfiles folder
cd $HOME/Downloads/dotfiles/bin/

# Use 'yes' to automatically answer all "Yes/No" prompts
echo ":: Automatically answering 'Yes' to all prompts"
yes | ./ml4w-hyprland-setup -m install

# Start Spinner
gum spin --spinner dot --title "Starting the setup now..." -- sleep 3

# Handle Update Prompt using expect
echo ":: Waiting for the update prompt and automatically answering 'y'"

expect <<EOF
spawn ./ml4w-hyprland-setup -p fedora
expect {
    "DO YOU WANT TO START THE UPDATE NOW?" { send "y\r"; exp_continue }
    timeout { send "y\r"; exp_continue }
}
expect eof
EOF

# Start setup for Fedora
if [ -f "./ml4w-hyprland-setup" ]; then
    echo ":: Starting Fedora setup..."
    yes | ./ml4w-hyprland-setup -p fedora
else
    echo ":: Error: ml4w-hyprland-setup not found or is not executable."
    exit 1
fi
