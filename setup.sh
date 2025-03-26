#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"

# Use user's home directory for models
USER_HOME="$HOME"
OUTPUT_DIR="$USER_HOME/models/llamafiles"
DOWNLOAD_DIR="$USER_HOME/models/huggingface"
CONFIG_DIR="$USER_HOME/.config/makelamafile"

# Latest llamafile release
LLAMAFILE_URL="https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.1/llamafile-0.9.1"
ZIPALIGN_URL="https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.1/zipalign-0.9.1"

# Function to check for macOS and M1
check_macos_m1() {
  echo "Checking system requirements..."
  
  if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This version is only compatible with macOS."
    exit 1
  fi
  
  # Check if we're on Apple Silicon
  if [ "$(uname -m)" != "arm64" ]; then
    echo "Warning: This version is optimized for Apple Silicon (M1/M2/M3)."
    echo "You're running on $(uname -m). Some features might not work optimally."
  fi
  
  echo "✅ macOS detected: $(sw_vers -productVersion)"
}

# Function to check dependencies
check_dependencies() {
  echo "Checking required dependencies..."
  
  # Check for curl
  if ! command -v curl &> /dev/null; then
    echo "Error: 'curl' is not installed. Please install it with Homebrew:"
    echo "brew install curl"
    exit 1
  fi
  
  # Check for Homebrew (helpful for users)
  if ! command -v brew &> /dev/null; then
    echo "Warning: Homebrew is not installed. It's recommended for managing dependencies."
    echo "Visit https://brew.sh for installation instructions."
  fi
  
  echo "✅ All required dependencies are installed."
}

# Function to create directory structure
create_directories() {
  echo "Creating directory structure..."
  mkdir -p "$BIN_DIR"
  mkdir -p "$OUTPUT_DIR"
  mkdir -p "$DOWNLOAD_DIR"
  mkdir -p "$CONFIG_DIR"
  echo "✅ Directory structure created."
}

# Function to download llamafile binaries
download_binaries() {
  echo "Downloading llamafile binaries..."
  
  # Download llamafile
  echo "Downloading llamafile from: $LLAMAFILE_URL"
  curl -L -o "$BIN_DIR/llamafile" "$LLAMAFILE_URL"
  chmod +x "$BIN_DIR/llamafile"
  
  # Download zipalign
  echo "Downloading zipalign from: $ZIPALIGN_URL"
  curl -L -o "$BIN_DIR/zipalign" "$ZIPALIGN_URL"
  chmod +x "$BIN_DIR/zipalign"
  
  echo "✅ Binaries downloaded and made executable."
}

# Function to create configuration file
create_config() {
  echo "Creating configuration file..."
  
  # Create config file with user paths
  cat > "$CONFIG_DIR/config" << EOF
# MakeLlamafile configuration
OUTPUT_DIR="$OUTPUT_DIR"
DOWNLOAD_DIR="$DOWNLOAD_DIR"
EOF
  
  echo "✅ Configuration created at $CONFIG_DIR/config"
}

# Function to verify binaries
verify_binaries() {
  echo "Verifying binaries..."
  
  if [ ! -x "$BIN_DIR/llamafile" ]; then
    echo "Error: llamafile binary is missing or not executable."
    exit 1
  fi
  
  if [ ! -x "$BIN_DIR/zipalign" ]; then
    echo "Error: zipalign binary is missing or not executable."
    exit 1
  fi
  
  echo "✅ Binary verification completed."
}

# Main setup process
echo "Starting MakeLlamafile setup for macOS..."
check_macos_m1
check_dependencies
create_directories
download_binaries
create_config
verify_binaries

echo ""
echo "✅ MakeLlamafile setup completed successfully!"
echo ""
echo "Your model directories have been set up at:"
echo "  $OUTPUT_DIR (for generated llamafiles)"
echo "  $DOWNLOAD_DIR (for downloaded models)"
echo ""
echo "You can now use the create_llamafile.sh script to convert GGUF models to llamafiles."
echo "Example: makelamafile path/to/model.gguf"
echo "" 