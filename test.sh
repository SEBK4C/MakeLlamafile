#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running MakeLlamafile macOS Tests${NC}"

# Test script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# User directories
USER_HOME="$HOME"
OUTPUT_DIR="$USER_HOME/models/llamafiles"
DOWNLOAD_DIR="$USER_HOME/models/huggingface"
CONFIG_DIR="$USER_HOME/.config/makelamafile"

# Determine bin directory - look in various locations
if [ -d "$SCRIPT_DIR/bin" ]; then
  BIN_DIR="$SCRIPT_DIR/bin"
elif [ -d "$(brew --prefix 2>/dev/null)/share/makelamafile/bin" ]; then
  BIN_DIR="$(brew --prefix)/share/makelamafile/bin"
elif [ -d "/usr/local/share/makelamafile/bin" ]; then
  BIN_DIR="/usr/local/share/makelamafile/bin"
elif [ -d "/opt/homebrew/share/makelamafile/bin" ]; then
  BIN_DIR="/opt/homebrew/share/makelamafile/bin"
else
  # Default fallback
  BIN_DIR="$SCRIPT_DIR/bin"
fi

# --------------------------------------
# Test 1: Checking system...
# --------------------------------------
echo -e "\n${YELLOW}Test 1: Checking system...${NC}"

if [ "$(uname)" != "Darwin" ]; then
  echo -e "${RED}❌ This version is only compatible with macOS${NC}"
  exit 1
fi

echo -e "✅ Running on macOS: $(sw_vers -productVersion)"
echo -e "✅ Architecture: $(uname -m)"

# --------------------------------------
# Test 2: Checking binaries...
# --------------------------------------
echo -e "\n${YELLOW}Test 2: Checking binaries...${NC}"

# Create bin directory if needed
mkdir -p "$BIN_DIR"

# If binaries don't exist in bin, download them
if [ ! -x "$BIN_DIR/llamafile" ] || [ ! -x "$BIN_DIR/zipalign" ]; then
  echo "Downloading required binaries..."
  
  # Download llamafile
  echo "Downloading llamafile..."
  curl -L -o "$BIN_DIR/llamafile" "https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.1/llamafile-0.9.1"
  chmod +x "$BIN_DIR/llamafile"
  
  # Download zipalign
  echo "Downloading zipalign..."
  curl -L -o "$BIN_DIR/zipalign" "https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.1/zipalign-0.9.1"
  chmod +x "$BIN_DIR/zipalign"
fi

# Check binaries again after potential download
if [ -x "$BIN_DIR/llamafile" ] && [ -x "$BIN_DIR/zipalign" ]; then
  echo -e "✅ Required binaries are available at $BIN_DIR"
else
  echo -e "${RED}❌ Required binaries are missing or not executable${NC}"
  exit 1
fi

# Create user directories if they don't exist
mkdir -p "$OUTPUT_DIR" "$DOWNLOAD_DIR" "$CONFIG_DIR"

# Create or update config file
cat > "$CONFIG_DIR/config" << EOF
# MakeLlamafile configuration
OUTPUT_DIR="$OUTPUT_DIR"
DOWNLOAD_DIR="$DOWNLOAD_DIR"
BIN_DIR="$BIN_DIR"
EOF

# Check user directories
if [ -d "$OUTPUT_DIR" ] && [ -d "$DOWNLOAD_DIR" ] && [ -f "$CONFIG_DIR/config" ]; then
  echo -e "✅ User directories and configuration are set up"
else
  echo -e "${RED}❌ Failed to set up user directories or configuration${NC}"
  exit 1
fi

# --------------------------------------
# Test 3: Testing model conversion...
# --------------------------------------
echo -e "\n${YELLOW}Test 3: Testing model conversion (small test model)...${NC}"

# Download tiny test model (uses a very small quantized model for testing)
echo "Downloading tiny test model..."
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf"
MODEL_FILE="$DOWNLOAD_DIR/test_model.gguf"

curl -L -o "$MODEL_FILE" "$MODEL_URL"

# Check if download was successful
if [[ ! -f "$MODEL_FILE" ]]; then
  echo -e "${RED}❌ Failed to download test model${NC}"
  exit 1
fi
echo "✅ Model downloaded successfully"

# Make create_llamafile.sh executable if it's not already
chmod +x "$SCRIPT_DIR/create_llamafile.sh"

# Make sure we export the BIN_DIR so the script knows where to find binaries
export BIN_DIR

# Convert the model
echo "Converting model to llamafile..."
"$SCRIPT_DIR/create_llamafile.sh" -n "test_model" "$MODEL_FILE"

# Check if llamafile was created in the output directory
if [[ -f "$OUTPUT_DIR/test_model/test_model.llamafile" ]]; then
  echo "✅ Llamafile created successfully"
else
  echo -e "${RED}❌ Failed to create llamafile${NC}"
  ls -la "$OUTPUT_DIR"
  exit 1
fi

# --------------------------------------
# Test 4: Validating the generated llamafile...
# --------------------------------------
echo -e "\n${YELLOW}Test 4: Validating the generated llamafile...${NC}"

LLAMAFILE_PATH="$OUTPUT_DIR/test_model/test_model.llamafile"

# Make the llamafile executable
chmod +x "$LLAMAFILE_PATH"

# Check if the file exists and is executable
if [ -x "$LLAMAFILE_PATH" ]; then
  echo "✅ Llamafile is executable"
  
  # Check file size (should be more than 1MB for a valid model)
  FILE_SIZE=$(stat -f%z "$LLAMAFILE_PATH")
  if [ "$FILE_SIZE" -gt 1000000 ]; then
    echo "✅ Llamafile has a valid size: $(du -h "$LLAMAFILE_PATH" | cut -f1)"
  else
    echo -e "${YELLOW}⚠️ Llamafile seems too small: $(du -h "$LLAMAFILE_PATH" | cut -f1)${NC}"
  fi
else
  echo -e "${RED}❌ Llamafile is not executable${NC}"
  exit 1
fi

# --------------------------------------
# Clean up
# --------------------------------------
echo -e "\n${YELLOW}Cleaning up...${NC}"
rm -f "$MODEL_FILE"
echo "✅ Test model file removed"

# --------------------------------------
# Final report
# --------------------------------------
echo -e "\n${GREEN}All tests completed!${NC}"
echo -e "${GREEN}MakeLlamafile is installed and ready to use.${NC}"
echo ""
echo "Your model directories are set up at:"
echo "  $OUTPUT_DIR (for generated llamafiles)"
echo "  $DOWNLOAD_DIR (for downloaded models)"
echo ""
echo "Configuration file: $CONFIG_DIR/config"
echo "Binary directory: $BIN_DIR" 