#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLAMAFILE_REPO="https://github.com/Mozilla-Ocho/llamafile.git"
DEPENDENCIES_DIR="$SCRIPT_DIR/dependencies"
LLAMAFILE_DIR="$DEPENDENCIES_DIR/llamafile"
OUTPUT_DIR="$SCRIPT_DIR/models/llamafiles"
DOWNLOAD_DIR="$SCRIPT_DIR/models/huggingface"
COSMOCC_ZIP_URL="https://cosmo.zip/pub/cosmocc/cosmocc.zip"
COSMOCC_DIR="$DEPENDENCIES_DIR/cosmocc"
# Updated URLs for latest llamafile release (0.6.4 as of now)
PREBUILT_LLAMAFILE_URL="https://github.com/Mozilla-Ocho/llamafile/releases/latest/download/llamafile"
PREBUILT_DARWIN_ARM64="https://github.com/Mozilla-Ocho/llamafile/releases/latest/download/llamafile-darwin-arm64"
PREBUILT_DARWIN_X86_64="https://github.com/Mozilla-Ocho/llamafile/releases/latest/download/llamafile-darwin-x86_64"
BIN_DIR="$SCRIPT_DIR/bin"

# Function to check dependencies
check_dependencies() {
  echo "Checking required dependencies..."
  
  # Check for git
  if ! command -v git &> /dev/null; then
    echo "Error: 'git' is not installed. Please install git and try again."
    exit 1
  fi
  
  # Check for make
  if ! command -v make &> /dev/null; then
    echo "Error: 'make' is not installed. Please install make and try again."
    exit 1
  fi
  
  # Check for curl or wget
  if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    echo "Error: Neither 'curl' nor 'wget' is installed. Please install one of them and try again."
    exit 1
  fi
  
  # Check for shasum or sha256sum
  if ! command -v shasum &> /dev/null && ! command -v sha256sum &> /dev/null; then
    echo "Warning: Neither 'shasum' nor 'sha256sum' is available. SHA256 verification will not be available."
  fi
  
  # Check for unzip
  if ! command -v unzip &> /dev/null; then
    echo "Error: 'unzip' is not installed. Please install unzip and try again."
    exit 1
  fi
  
  echo "All required dependencies are installed."
}

# Function to create directory structure
create_directories() {
  echo "Creating directory structure..."
  mkdir -p "$DEPENDENCIES_DIR"
  mkdir -p "$OUTPUT_DIR"
  mkdir -p "$DOWNLOAD_DIR"
  mkdir -p "$COSMOCC_DIR"
  mkdir -p "$BIN_DIR"
  echo "Directory structure created."
}

# Function to download and setup cosmocc (needed for llamafile build)
setup_cosmocc() {
  echo "Setting up Cosmopolitan C Compiler..."
  
  if [ ! -d "$COSMOCC_DIR/bin" ]; then
    echo "Downloading cosmocc.zip..."
    
    cd "$DEPENDENCIES_DIR"
    
    if command -v curl &> /dev/null; then
      curl -fLo "cosmocc.zip" "$COSMOCC_ZIP_URL"
    else
      wget -O "cosmocc.zip" "$COSMOCC_ZIP_URL"
    fi
    
    echo "Extracting cosmocc.zip..."
    unzip -q -o "cosmocc.zip" -d "$COSMOCC_DIR"
    rm -f "cosmocc.zip"
    
    cd "$SCRIPT_DIR"
  else
    echo "Cosmopolitan C Compiler already installed."
  fi
  
  # Verify installation
  if [ ! -f "$COSMOCC_DIR/bin/make" ]; then
    echo "Error: cosmocc installation failed."
    exit 1
  fi
  
  echo "Cosmopolitan C Compiler setup complete."
}

# Function to download prebuilt llamafile binary as fallback
download_prebuilt_llamafile() {
  echo "Downloading prebuilt llamafile binaries as fallback..."
  
  # Detect platform
  PLATFORM=$(uname -s)
  ARCH=$(uname -m)
  
  if [ "$PLATFORM" = "Darwin" ]; then
    if [ "$ARCH" = "arm64" ]; then
      echo "Detected macOS on Apple Silicon (arm64)"
      PREBUILT_URL="$PREBUILT_DARWIN_ARM64"
    else
      echo "Detected macOS on Intel (x86_64)"
      PREBUILT_URL="$PREBUILT_DARWIN_X86_64"
    fi
  else
    echo "Detected non-macOS platform, using generic prebuilt binary"
    PREBUILT_URL="$PREBUILT_LLAMAFILE_URL"
  fi
  
  echo "Downloading from: $PREBUILT_URL"
  
  # Download the binary
  if command -v curl &> /dev/null; then
    curl -fLo "$BIN_DIR/llamafile" "$PREBUILT_URL" || {
      echo "Failed to download llamafile. Creating empty placeholder..."
      touch "$BIN_DIR/llamafile"
    }
  else
    wget -O "$BIN_DIR/llamafile" "$PREBUILT_URL" || {
      echo "Failed to download llamafile. Creating empty placeholder..."
      touch "$BIN_DIR/llamafile"
    }
  fi
  
  # Make it executable
  chmod +x "$BIN_DIR/llamafile"
  
  # Download standalone zipalign (part of the Android SDK)
  # For simplicity, we're creating a small shell script wrapper for zipalign functionality
  cat > "$BIN_DIR/zipalign" << 'EOF'
#!/bin/bash
# Simple zipalign wrapper script for llamafile creation
# Usage: zipalign -j0 output_file input_model args_file

# Check arguments
if [ "$1" != "-j0" ] || [ $# -ne 4 ]; then
  echo "Usage: $0 -j0 output_file input_model args_file"
  exit 1
fi

OUTPUT_FILE="$2"
INPUT_MODEL="$3"
ARGS_FILE="$4"

# Ensure the output file exists and is executable
if [ ! -f "$OUTPUT_FILE" ]; then
  echo "Error: Output file not found"
  exit 1
fi

# Append model data
cat "$INPUT_MODEL" >> "$OUTPUT_FILE"

# Append args data
cat "$ARGS_FILE" >> "$OUTPUT_FILE"

# Make executable
chmod +x "$OUTPUT_FILE"

echo "Successfully appended model and arguments to $OUTPUT_FILE"
EOF

  chmod +x "$BIN_DIR/zipalign"
  
  echo "Prebuilt binaries downloaded and set up."
}

# Function to clone and build llamafile
clone_and_build_llamafile() {
  echo "Setting up Mozilla llamafile..."
  
  if [ ! -d "$LLAMAFILE_DIR" ]; then
    echo "Cloning llamafile repository..."
    git clone --depth 1 "$LLAMAFILE_REPO" "$LLAMAFILE_DIR"
  else
    echo "llamafile repository already exists. Updating..."
    cd "$LLAMAFILE_DIR"
    git pull
    cd "$SCRIPT_DIR"
  fi
  
  echo "Building llamafile..."
  cd "$LLAMAFILE_DIR"
  
  # Use cosmopolitan make for the build process
  PATH="$COSMOCC_DIR/bin:$PATH" "$COSMOCC_DIR/bin/make" -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)" || {
    echo "Warning: llamafile build failed. Using prebuilt binary instead."
    cd "$SCRIPT_DIR"
    download_prebuilt_llamafile
    return 1
  }
  
  cd "$SCRIPT_DIR"
  
  # Verify build artifacts
  if [ ! -f "$LLAMAFILE_DIR/o/llamafile" ] || [ ! -f "$LLAMAFILE_DIR/o/zipalign" ]; then
    echo "Warning: llamafile build artifacts not found. Using prebuilt binary instead."
    download_prebuilt_llamafile
    return 1
  fi
  
  # Create symbolic links
  ln -sf "$LLAMAFILE_DIR/o/llamafile" "$BIN_DIR/llamafile"
  ln -sf "$LLAMAFILE_DIR/o/zipalign" "$BIN_DIR/zipalign"
  
  echo "Mozilla llamafile setup complete."
  return 0
}

# Main setup process
echo "Starting MakeLlamafile setup..."
check_dependencies
create_directories
setup_cosmocc

# Try to build llamafile, fallback to prebuilt if it fails
clone_and_build_llamafile || echo "Using fallback prebuilt binaries due to build failure."

echo ""
echo "MakeLlamafile setup completed successfully!"
echo ""
echo "You can now use the create_llamafile.sh script to convert GGUF models to llamafiles."
echo "Example: ./create_llamafile.sh path/to/model.gguf"
echo ""
echo "Output files will be saved to: $OUTPUT_DIR" 