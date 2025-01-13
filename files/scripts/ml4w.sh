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
    sudo dnf install --assumeyes "${toInstall[@]}"
}

# Function to capture output and extract paths
capture_paths() {
    # Create a temporary file to store the installation output
    temp_output=$(mktemp)
    
    # Run the command and capture its output
    "$@" | tee "$temp_output"
    
    # Extract paths that start with "/" from the output
    grep -o '/[[:alnum:]/_.-]*' "$temp_output" | sort -u > "$HOME/.ml4w_paths"
    
    rm "$temp_output"
}

# Install Gum if not installed
install_gum() {
    echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo
    capture_paths sudo yum install --assumeyes gum
}

# Install Expect if not installed
install_expect() {
    if ! command -v expect &>/dev/null; then
        echo ":: Installing expect..."
        sudo dnf install --assumeyes expect
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
RED='\033[0;31m'

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

# Handle setup using expect
echo ":: Starting Fedora setup with automatic responses"

expect <<EOF
spawn ./ml4w-hyprland-setup -p fedora
expect {
    "DO YOU WANT TO START THE UPDATE NOW?" { send "y\r"; exp_continue }
    "Would you like to reboot now?" { 
        send "y\r"
        # Add a small delay before exiting
        sleep 2
        exit 0
    }
    timeout { send "y\r"; exp_continue }
}
expect eof
EOF

# Add trap to handle the exit
trap 'echo "Installation complete. System will reboot now."; exit 0' EXIT

# Check if critical files and directories exist after installation
echo ":: Verifying installation..."

critical_paths=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/kitty"
    "$HOME/.config/rofi"
    "$HOME/.local/share/fonts"
)

critical_files=(
    "$HOME/.config/hypr/hyprland.conf"
    "$HOME/.config/waybar/config"
    "$HOME/.config/waybar/style.css"
    "$HOME/.config/kitty/kitty.conf"
    "$HOME/.config/rofi/config.rasi"
)

# Check directories
missing_paths=()
for path in "${critical_paths[@]}"; do
    if [ ! -d "$path" ]; then
        missing_paths+=("$path")
    fi
done

# Check files
missing_files=()
for file in "${critical_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

# Display results
if [ ${#missing_paths[@]} -eq 0 ] && [ ${#missing_files[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All required files and directories are in place${NONE}"
else
    if [ ${#missing_paths[@]} -gt 0 ]; then
        echo -e "${RED}Warning: The following directories are missing:${NONE}"
        printf '%s\n' "${missing_paths[@]}"
    fi
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo -e "${RED}Warning: The following files are missing:${NONE}"
        printf '%s\n' "${missing_files[@]}"
    fi
    exit 1
fi

# Add this before the verification section
echo ":: Checking if all files were moved correctly..."

# Check if we have a paths file
if [ -f "$HOME/.ml4w_paths" ]; then
    missing_moved_files=()
    while IFS= read -r path; do
        if [ ! -e "$path" ]; then
            missing_moved_files+=("$path")
        fi
    done < "$HOME/.ml4w_paths"

    if [ ${#missing_moved_files[@]} -gt 0 ]; then
        echo -e "${RED}Warning: The following files/directories were not moved correctly:${NONE}"
        printf '%s\n' "${missing_moved_files[@]}"
        exit 1
    else
        echo -e "${GREEN}✓ All files were moved to their correct locations${NONE}"
    fi
    
    # Clean up paths file
    rm "$HOME/.ml4w_paths"
else
    echo -e "${RED}Warning: Could not verify file movements - no path information available${NONE}"
fi
