#!/bin/bash
# Version 1.0.0
# Enable pipefail so we can get the exit status of 'make' even when piping to 'tee'
set -o pipefail

# Configuration Variables
ANDROID_DIR="$HOME/Desktop/android"
TARGET_FILE="$ANDROID_DIR/build_target.txt" # Make sure to create this file!
LOG_FILE="/tmp/android_build.log"

# 1. Change to the Android directory
echo "Navigating to $ANDROID_DIR..."
cd "$ANDROID_DIR" || {
    zenity --error --title="Directory Error" --text="Failed to cd to $ANDROID_DIR"
    exit 1
}

# 2. Read the target number from the first line of the text file
if [ ! -f "$TARGET_FILE" ]; then
    zenity --error --title="Missing Target File" --text="Target file not found at: $TARGET_FILE\n\nPlease create it and put the build target number on the first line."
    exit 1
fi

BUILD_TARGET=$(head -n 1 "$TARGET_FILE")
echo "Loaded build target '$BUILD_TARGET' from $TARGET_FILE"

# 3. Setup the build environment
if [ ! -f "build/envsetup.sh" ]; then
    zenity --error --title="Environment Setup Error" --text="build/envsetup.sh not found in $ANDROID_DIR."
    exit 1
fi

echo "Sourcing build/envsetup.sh..."
source build/envsetup.sh

# 4. Run lunch with the target
# Passing the target directly to lunch prevents it from stopping to prompt the user
echo "Running lunch for target $BUILD_TARGET..."
lunch "$BUILD_TARGET" || {
    zenity --error --title="Lunch Failed" --text="Failed to configure lunch for target: $BUILD_TARGET"
    exit 1
}

# 5. Run make and log the output
echo "Starting make -j$(nproc)..."
# 'tee' allows you to see the output in the terminal while simultaneously saving it to LOG_FILE
make -j$(nproc) 2>&1 | tee "$LOG_FILE"
MAKE_STATUS=$?

# 6. Show the graphical popup with the results and logs
if [ $MAKE_STATUS -eq 0 ]; then
    (echo "======================================"; \
     echo "         BUILD SUCCESSFUL             "; \
     echo "======================================"; \
     echo ""; \
     cat "$LOG_FILE") | zenity --text-info \
                               --title="Build Status: SUCCESS" \
                               --width=800 \
                               --height=600
else
    (echo "======================================"; \
     echo "           BUILD FAILED               "; \
     echo "======================================"; \
     echo ""; \
     cat "$LOG_FILE") | zenity --text-info \
                               --title="Build Status: FAILED" \
                               --width=800 \
                               --height=600
fi

# Exit with the same status 'make' exited with
exit $MAKE_STATUS
