#!/bin/bash

# Define the repository and version
REPO_URL="https://github.com/mylinuxforwork/dotfiles.git"
DEST_DIR="$HOME/Downloads/dotfiles"
LATEST_VERSION="main"  # Replace with the actual version/branch you want

# Step 1: Clone the repository
echo "Cloning the repository..."
git clone --branch "$LATEST_VERSION" "$REPO_URL" "$DEST_DIR"

# Check if the clone was successful
if [ ! -d "$DEST_DIR" ]; then
    echo "Failed to clone the repository. Exiting."
    exit 1
fi

# Step 2: Change to the required directory
BIN_DIR="$DEST_DIR/bin/"
if [ -d "$BIN_DIR" ]; then
    cd "$BIN_DIR"
else
    echo "Directory $BIN_DIR does not exist! Exiting."
    exit 1
fi

# Step 3: Check if the setup script exists and is executable
if [ -f "./ml4w-hyprland-setup" ]; then
    chmod +x ./ml4w-hyprland-setup
else
    echo "ml4w-hyprland-setup script is missing! Exiting."
    exit 1
fi

# Step 4: Run the setup script in a non-TTY environment (use gum spin if TTY, fallback to echo)
if [ -t 1 ]; then
    gum spin --spinner dot --title "Starting the installation now..." -- sleep 3
else
    echo "Starting the installation now..."
fi

# Step 5: Run the setup script for installation and interact automatically
echo "Running the setup script..."

# Use expect for automatic responses
expect << EOF
spawn ./ml4w-hyprland-setup -m install
expect {
    -re "(Do you want to start the update now?|Are you sure you want to continue?|Proceed with the update?|Is this ok?|Continue with the installation?)" {
        send "y\r"
        exp_continue
    }
    eof
}
EOF

if [ $? -ne 0 ]; then
    echo "Installation failed during setup! Exiting."
    exit 1
fi

# Step 6: Run the setup script for Fedora
echo "Running the setup script for Fedora..."

# Use expect for automatic responses
expect << EOF
spawn ./ml4w-hyprland-setup -p fedora
expect {
    -re "(Do you want to start the update now?|Are you sure you want to continue?|Proceed with the update?|Is this ok?|Continue with the installation?)" {
        send "y\r"
        exp_continue
    }
    eof
}
EOF

if [ $? -ne 0 ]; then
    echo "Fedora setup failed! Exiting."
    exit 1
fi

# Step 7: Verify installation files in /usr/
echo "Checking for installation files in /usr/..."

# Define the directories to search for installation files
INSTALL_DIRS=("/usr/bin" "/usr/local/bin" "/usr/share" "/usr/lib")

# Search for specific files installed (you can adjust the filenames or patterns based on your setup)
SEARCH_FILES=("ml4w-hyprland-setup" "dotfiles" "ml4w")

# Loop through directories and search for files
for DIR in "${INSTALL_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        for FILE in "${SEARCH_FILES[@]}"; do
            FOUND=$(find "$DIR" -type f -name "$FILE" 2>/dev/null)
            if [ -n "$FOUND" ]; then
                echo "Found: $FOUND"
            else
                echo "Not found: $FILE in $DIR"
            fi
        done
    else
        echo "Directory $DIR does not exist."
    fi
done

# Step 8: Final confirmation
echo "Setup completed successfully!"

# Optional: Additional steps can be added based on specific requirements for post-setup actions.
