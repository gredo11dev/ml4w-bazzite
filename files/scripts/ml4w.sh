#!/bin/bash

# Define the repository and version
REPO_URL="https://github.com/mylinuxforwork/dotfiles.git"
DEST_DIR="$HOME/Downloads/dotfiles"
LATEST_VERSION="main"

# Check if running in Bluebuild environment
if [ ! -f "/usr/bin/rpm-ostree" ]; then
    echo "This script requires rpm-ostree (Bluebuild/Silverblue environment)"
    exit 1
fi

# Step 1: Install required dependencies via rpm-ostree
echo "Installing required dependencies..."
rpm-ostree install --apply-live \
    expect \
    git \
    gum \
    findutils || {
    echo "Failed to install dependencies. Exiting."
    exit 1
}

# Step 2: Clone the repository
echo "Cloning the repository..."
git clone --branch "$LATEST_VERSION" "$REPO_URL" "$DEST_DIR" || {
    echo "Failed to clone the repository. Exiting."
    exit 1
}

# Step 3: Change to the required directory
BIN_DIR="$DEST_DIR/bin/"
if [ ! -d "$BIN_DIR" ]; then
    echo "Directory $BIN_DIR does not exist! Exiting."
    exit 1
fi
cd "$BIN_DIR" || exit 1

# Step 4: Check if the setup script exists and is executable
if [ ! -f "./ml4w-hyprland-setup" ]; then
    echo "ml4w-hyprland-setup script is missing! Exiting."
    exit 1
fi
chmod +x ./ml4w-hyprland-setup

# Step 5: Create temporary overlay for installation
echo "Creating temporary overlay..."
mkdir -p "$HOME/.local/share/ml4w-overlay"
export ML4W_OVERLAY_DIR="$HOME/.local/share/ml4w-overlay"

# Step 6: Run the setup script in a non-TTY environment
if [ -t 1 ]; then
    gum spin --spinner dot --title "Starting the installation now..." -- sleep 3
else
    echo "Starting the installation now..."
fi

# Step 7: Run the setup script for installation with overlay support
echo "Running the setup script..."
expect << EOF
spawn ./ml4w-hyprland-setup -m install --overlay-dir="$ML4W_OVERLAY_DIR"
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

# Step 8: Run the setup script for Fedora Silverblue/Bluebuild
echo "Running the setup script for Fedora Silverblue..."
expect << EOF
spawn ./ml4w-hyprland-setup -p fedora-silverblue --overlay-dir="$ML4W_OVERLAY_DIR"
expect {
    -re "(Do you want to start the update now?|Are you sure you want to continue?|Proceed with the update?|Is this ok?|Continue with the installation?)" {
        send "y\r"
        exp_continue
    }
    eof
}
EOF

if [ $? -ne 0 ]; then
    echo "Fedora Silverblue setup failed! Exiting."
    exit 1
fi

# Step 9: Verify installation files in overlay directory
echo "Checking for installation files..."
SEARCH_FILES=("ml4w-hyprland-setup" "dotfiles" "ml4w")

for FILE in "${SEARCH_FILES[@]}"; do
    FOUND=$(find "$ML4W_OVERLAY_DIR" -type f -name "$FILE" 2>/dev/null)
    if [ -n "$FOUND" ]; then
        echo "Found: $FOUND"
    else
        echo "Not found: $FILE in overlay directory"
    fi
done

# Step 10: Apply overlay changes
echo "Applying overlay changes..."
if [ -d "$ML4W_OVERLAY_DIR" ]; then
    # Copy overlay contents to appropriate locations
    for dir in "$ML4W_OVERLAY_DIR"/*; do
        if [ -d "$dir" ]; then
            base_dir=$(basename "$dir")
            if [ "$base_dir" = "usr" ]; then
                sudo cp -r "$dir"/* /usr/
            else
                cp -r "$dir"/* "$HOME/.$base_dir"
            fi
        fi
    done
fi

# Step 11: Cleanup
echo "Cleaning up..."
rm -rf "$ML4W_OVERLAY_DIR"

# Step 12: Final confirmation
echo "Setup completed successfully!"
echo "Please reboot your system to apply all changes."
