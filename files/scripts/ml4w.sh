#!/bin/bash
clear

repo="mylinuxforwork/dotfiles"

# Get the latest tag from GitHub
get_latest_release() {
  curl --silent "https://api.github.com/repos/$repo/releases/latest" | 
    grep '"tag_name":' | 
    sed -E 's/.*"([^"]+)".*/\1/'
}

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

# Automatically clone the "main-release" without interaction
echo ":: Automatically installing Main Release"

# Clone the main release directly without any prompts
git clone --branch $latest_version --depth 1 https://github.com/mylinuxforwork/dotfiles.git ~/Downloads/dotfiles

echo ":: Download complete."
echo

# Cd into dotfiles folder
cd $HOME/Downloads/dotfiles/bin/

# Use 'yes' to automatically answer initial setup prompts
echo ":: Automatically running the main setup script"
yes | ./ml4w-hyprland-setup -m install

# Handle update prompt using expect
echo ":: Interacting with the update prompt using 'expect'"

expect <<EOF
spawn ./ml4w-hyprland-setup -p fedora
expect {
    "DO YOU WANT TO START THE UPDATE NOW?" { send "y\r"; exp_continue }
    timeout { send "y\r"; exp_continue }
}
expect eof
EOF

# Start Fedora-specific setup
if [ -f "./ml4w-hyprland-setup" ]; then
    echo ":: Starting Fedora-specific setup..."
    expect <<EOF
spawn ./ml4w-hyprland-setup -p fedora
expect {
    "DO YOU WANT TO CONTINUE WITH THE SETUP?" { send "y\r"; exp_continue }
    timeout { send "y\r"; exp_continue }
}
expect eof
EOF
else
    echo ":: Error: ml4w-hyprland-setup not found or is not executable."
    exit 1
fi
