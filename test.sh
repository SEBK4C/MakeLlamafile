#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running MakeLlamafile Function Tests${NC}"

# Test script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# User directories
USER_HOME="$HOME"
OUTPUT_DIR="$USER_HOME/models/llamafiles"
DOWNLOAD_DIR="$USER_HOME/models/huggingface"
CONFIG_DIR="$USER_HOME/.config/makelamafile"
TEST_OUTPUT_DIR="$OUTPUT_DIR/test_results"

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

# Test tiny model could be in several locations - look for it
TINY_MODEL=""
POSSIBLE_PATHS=(
  # From Homebrew installation
  "$(brew --prefix 2>/dev/null)/share/makelamafile/models/TinyLLama-v0.1-5M-F16.gguf"
  "/usr/local/share/makelamafile/models/TinyLLama-v0.1-5M-F16.gguf"
  "/opt/homebrew/share/makelamafile/models/TinyLLama-v0.1-5M-F16.gguf"
  # From the llamafile repository
  "$SCRIPT_DIR/dependencies/llamafile/models/TinyLLama-v0.1-5M-F16.gguf"
  # As a local file
  "$SCRIPT_DIR/models/TinyLLama-v0.1-5M-F16.gguf"
)

for path in "${POSSIBLE_PATHS[@]}"; do
  if [ -f "$path" ]; then
    TINY_MODEL="$path"
    break
  fi
done

# --------------------------------------
# Test 1: Checking system and setup
# --------------------------------------
echo -e "\n${BLUE}Test 1: Checking system and setup...${NC}"

if [ "$(uname)" != "Darwin" ]; then
  echo -e "${RED}❌ This version is only compatible with macOS${NC}"
  exit 1
fi

echo -e "✅ Running on macOS: $(sw_vers -productVersion)"
echo -e "✅ Architecture: $(uname -m)"

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
mkdir -p "$OUTPUT_DIR" "$DOWNLOAD_DIR" "$CONFIG_DIR" "$TEST_OUTPUT_DIR"

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
# Test 2: Testing test model access
# --------------------------------------
echo -e "\n${BLUE}Test 2: Testing access to the test model...${NC}"

# If we didn't find the test model, download a tiny one
if [ -z "$TINY_MODEL" ]; then
  echo "Test model not found in standard locations. Downloading test model..."
  TINY_MODEL="$DOWNLOAD_DIR/TinyLLama-v0.1-5M-F16.gguf"
  curl -L -o "$TINY_MODEL" "https://huggingface.co/ggml-org/models/resolve/main/TinyLLama-v0.1-5M-F16.gguf"
  
  if [ ! -f "$TINY_MODEL" ]; then
    echo -e "${RED}❌ Failed to download test model${NC}"
    exit 1
  fi
fi

echo -e "✅ Using test model: $TINY_MODEL"

# --------------------------------------
# Test 3: Test basic conversion
# --------------------------------------
echo -e "\n${BLUE}Test 3: Testing basic conversion...${NC}"

# Make create_llamafile.sh executable if it's not already
chmod +x "$SCRIPT_DIR/create_llamafile.sh"

# Make sure we export the BIN_DIR so the script knows where to find binaries
export BIN_DIR

# Convert the model with default options
echo "Converting model to llamafile with default options..."
"$SCRIPT_DIR/create_llamafile.sh" -n "TinyLLama-basic" "$TINY_MODEL"

# Check if llamafile was created
if [[ -f "$OUTPUT_DIR/TinyLLama-basic/TinyLLama-basic.llamafile" && -x "$OUTPUT_DIR/TinyLLama-basic/TinyLLama-basic.llamafile" ]]; then
  echo -e "✅ Basic conversion successful"
else
  echo -e "${RED}❌ Basic conversion failed${NC}"
  exit 1
fi

# --------------------------------------
# Test 4: Test with custom output directory
# --------------------------------------
echo -e "\n${BLUE}Test 4: Testing custom output directory...${NC}"

# Convert with custom output directory
echo "Converting model with custom output directory..."
"$SCRIPT_DIR/create_llamafile.sh" -o "$TEST_OUTPUT_DIR" -n "TinyLLama-custom-dir" "$TINY_MODEL"

# Check if llamafile was created in the custom directory
if [[ -f "$TEST_OUTPUT_DIR/TinyLLama-custom-dir/TinyLLama-custom-dir.llamafile" && -x "$TEST_OUTPUT_DIR/TinyLLama-custom-dir/TinyLLama-custom-dir.llamafile" ]]; then
  echo -e "✅ Custom output directory test successful"
else
  echo -e "${RED}❌ Custom output directory test failed${NC}"
  exit 1
fi

# --------------------------------------
# Test 5: Test with custom description
# --------------------------------------
echo -e "\n${BLUE}Test 5: Testing custom description...${NC}"

# Convert with custom description
echo "Converting model with custom description..."
CUSTOM_DESC="This is a custom description for testing purposes"
"$SCRIPT_DIR/create_llamafile.sh" -d "$CUSTOM_DESC" -n "TinyLLama-custom-desc" "$TINY_MODEL"

# Check if README contains the custom description
if grep -q "$CUSTOM_DESC" "$OUTPUT_DIR/TinyLLama-custom-desc/README.md"; then
  echo -e "✅ Custom description test successful"
else
  echo -e "${RED}❌ Custom description test failed${NC}"
  exit 1
fi

# --------------------------------------
# Test 6: Test with test option
# --------------------------------------
echo -e "\n${BLUE}Test 6: Testing model testing option...${NC}"

# Convert with test option
echo "Converting model with test option..."
TEST_OUTPUT=$("$SCRIPT_DIR/create_llamafile.sh" -t -n "TinyLLama-test-option" "$TINY_MODEL" 2>&1)

# Check if test was performed
if echo "$TEST_OUTPUT" | grep -q "Testing llamafile with prompt"; then
  echo -e "✅ Test option successful"
else
  echo -e "${RED}❌ Test option failed${NC}"
  exit 1
fi

# --------------------------------------
# Test 7: Test with custom prompt
# --------------------------------------
echo -e "\n${BLUE}Test 7: Testing custom prompt...${NC}"

# Convert with custom prompt
CUSTOM_PROMPT="What is artificial intelligence?"
TEST_OUTPUT=$("$SCRIPT_DIR/create_llamafile.sh" -p "$CUSTOM_PROMPT" -n "TinyLLama-custom-prompt" "$TINY_MODEL" 2>&1)

# Check if the custom prompt was used
if echo "$TEST_OUTPUT" | grep -q "$CUSTOM_PROMPT"; then
  echo -e "✅ Custom prompt test successful"
else
  echo -e "${RED}❌ Custom prompt test failed${NC}"
  exit 1
fi

# --------------------------------------
# Final test: Check expected home directory llamafile
# --------------------------------------
echo -e "\n${BLUE}Final test: Creating ~/models/llamafiles/TinyLLama-v0.1-5M-F16.llamafile...${NC}"

# Convert the model to the expected path
"$SCRIPT_DIR/create_llamafile.sh" -n "TinyLLama-v0.1-5M-F16" "$TINY_MODEL"

# Check if the expected llamafile exists
if [[ -f "$OUTPUT_DIR/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile" && -x "$OUTPUT_DIR/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile" ]]; then
  echo -e "✅ Final test successful!"
  echo -e "   Created: $OUTPUT_DIR/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile"
else
  echo -e "${RED}❌ Final test failed${NC}"
  exit 1
fi

# --------------------------------------
# Clean up
# --------------------------------------
echo -e "\n${YELLOW}Cleaning up test artifacts...${NC}"
rm -rf "$TEST_OUTPUT_DIR"
echo -e "✅ Test artifacts removed"

# --------------------------------------
# Final report
# --------------------------------------
echo -e "\n${GREEN}All function tests completed successfully!${NC}"
echo -e "${GREEN}MakeLlamafile is fully functional.${NC}"
echo ""
echo "Your model directories are set up at:"
echo "  $OUTPUT_DIR (for generated llamafiles)"
echo "  $DOWNLOAD_DIR (for downloaded models)"
echo ""
echo "The test model has been converted and is available at:"
echo "  $OUTPUT_DIR/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile"
echo ""
echo "You can try running it with:"
echo "  $OUTPUT_DIR/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile"
echo ""
echo "Configuration: $CONFIG_DIR/config"
echo "Binaries: $BIN_DIR" 