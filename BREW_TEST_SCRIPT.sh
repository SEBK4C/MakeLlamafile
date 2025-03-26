#!/bin/bash
# Test script for MakeLlamafile Homebrew formula
# This script tests the installation and functionality of the makelamafile package

set -e  # Exit immediately if a command exits with a non-zero status
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running MakeLlamafile Homebrew Formula Tests${NC}"

# --------------------------------------
# Test 1: Check if installation was successful
# --------------------------------------
echo -e "\n${YELLOW}Test 1: Verifying installation...${NC}"

# Check binaries
for cmd in makelamafile llamafile zipalign; do
  if command -v $cmd &> /dev/null; then
    echo -e "✅ $cmd is installed: $(which $cmd)"
  else
    echo -e "${RED}❌ $cmd not found in PATH${NC}"
    exit 1
  fi
done

# Check directories
SHARE_DIR="$(brew --prefix)/share/makelamafile"
CONFIG_FILE=""

# Try to find the config file in various possible locations
if [[ -f "$(brew --prefix)/etc/makelamafile/config" ]]; then
  CONFIG_FILE="$(brew --prefix)/etc/makelamafile/config"
elif [[ -f "$HOME/.config/makelamafile/config" ]]; then
  CONFIG_FILE="$HOME/.config/makelamafile/config"
else
  echo -e "${YELLOW}⚠️ Searching for config file...${NC}"
  CONFIG_FILE=$(find "$(brew --prefix)" "$HOME" -name "config" -path "*makelamafile*" 2>/dev/null | head -n 1)
fi

if [[ -d "$SHARE_DIR" ]]; then
  echo -e "✅ Share directory exists: $SHARE_DIR"
else
  echo -e "${RED}❌ Share directory not found: $SHARE_DIR${NC}"
  exit 1
fi

if [[ -f "$CONFIG_FILE" ]]; then
  echo -e "✅ Configuration file exists: $CONFIG_FILE"
else
  echo -e "${RED}❌ Configuration file not found. Checked in standard locations.${NC}"
  exit 1
fi

# --------------------------------------
# Test 2: Check help output
# --------------------------------------
echo -e "\n${YELLOW}Test 2: Testing help command...${NC}"
HELP_OUTPUT=$(makelamafile --help)

if [[ "$HELP_OUTPUT" == *"Usage:"* ]]; then
  echo -e "✅ Help command works correctly"
else
  echo -e "${RED}❌ Help command output doesn't contain expected text${NC}"
  exit 1
fi

# --------------------------------------
# Test 3: Download and convert a tiny model
# --------------------------------------
echo -e "\n${YELLOW}Test 3: Testing model conversion (small test model)...${NC}"

# Create temporary test directory
TEST_DIR=$(mktemp -d)
echo "Using temporary directory: $TEST_DIR"
cd "$TEST_DIR"

# Download tiny test model (uses a very small quantized model for testing)
echo "Downloading tiny test model..."
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf"
MODEL_FILE="$TEST_DIR/test_model.gguf"

if command -v curl &> /dev/null; then
  curl -L -o "$MODEL_FILE" "$MODEL_URL"
elif command -v wget &> /dev/null; then
  wget -O "$MODEL_FILE" "$MODEL_URL"
else
  echo -e "${RED}❌ Neither curl nor wget is available${NC}"
  exit 1
fi

# Check if download was successful
if [[ ! -f "$MODEL_FILE" ]]; then
  echo -e "${RED}❌ Failed to download test model${NC}"
  exit 1
fi
echo "✅ Model downloaded successfully"

# Convert the model
echo "Converting model to llamafile..."
makelamafile -n "test_model" "$MODEL_FILE"

# Get output directory from config
OUTPUT_DIR=$(grep "OUTPUT_DIR" "$CONFIG_FILE" | cut -d'"' -f2)
if [[ -z "$OUTPUT_DIR" ]]; then
  # Fallback to default location if not found in config
  OUTPUT_DIR="$HOME/models/llamafiles"
  echo -e "${YELLOW}⚠️ Couldn't extract OUTPUT_DIR from config, using default: $OUTPUT_DIR${NC}"
fi

LLAMAFILE_PATH="$OUTPUT_DIR/test_model/test_model.llamafile"

# Verify llamafile creation
if [[ -f "$LLAMAFILE_PATH" ]]; then
  echo "✅ Llamafile created successfully at: $LLAMAFILE_PATH"
else
  echo -e "${RED}❌ Failed to create llamafile at: $LLAMAFILE_PATH${NC}"
  echo "Checking other possible locations..."
  find "$HOME" -name "test_model.llamafile" 2>/dev/null
  exit 1
fi

# Check if llamafile is executable
if [[ -x "$LLAMAFILE_PATH" ]]; then
  echo "✅ Llamafile is executable"
else
  echo -e "${RED}❌ Llamafile is not executable${NC}"
  exit 1
fi

# --------------------------------------
# Test 4: Test the generated llamafile
# --------------------------------------
echo -e "\n${YELLOW}Test 4: Testing the generated llamafile...${NC}"
echo "Running very basic inference test (may take a moment)..."

# Run a very simple test with the model
# -e ensures non-interactive mode, -n limits token generation, -p provides the prompt
INFERENCE_OUTPUT=$(timeout 60s "$LLAMAFILE_PATH" -e -n 5 -p "Hello" 2>/dev/null || echo "Timeout or error occurred")

if [[ "$INFERENCE_OUTPUT" != "" && "$INFERENCE_OUTPUT" != *"Timeout or error occurred"* ]]; then
  echo "✅ Llamafile produced output when prompted"
  echo -e "  ${YELLOW}Preview:${NC} ${INFERENCE_OUTPUT:0:100}..."
else
  echo -e "${RED}❌ Llamafile failed to produce output or timed out${NC}"
  exit 1
fi

# --------------------------------------
# Test 5: Verify documentation
# --------------------------------------
echo -e "\n${YELLOW}Test 5: Checking for documentation...${NC}"
DOC_DIR="$(brew --prefix)/share/doc/makelamafile"

if [[ -d "$DOC_DIR" ]]; then
  echo "✅ Documentation directory exists: $DOC_DIR"
  if [[ -f "$DOC_DIR/README.md" ]]; then
    echo "✅ README.md exists"
  else
    echo -e "${YELLOW}⚠️ README.md not found in documentation directory${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ Documentation directory not found: $DOC_DIR${NC}"
fi

# --------------------------------------
# Clean up
# --------------------------------------
echo -e "\n${YELLOW}Cleaning up...${NC}"
cd
rm -rf "$TEST_DIR"
echo "✅ Temporary files removed"

# --------------------------------------
# Final report
# --------------------------------------
echo -e "\n${GREEN}All tests passed successfully!${NC}"
echo -e "${GREEN}MakeLlamafile is correctly installed and functioning.${NC}"
echo ""
echo "Installation information:"
echo "  - Binary location: $(which makelamafile)"
echo "  - Model output directory: $OUTPUT_DIR"
echo "  - Configuration: $CONFIG_FILE"
echo ""
echo "Usage example:"
echo "  makelamafile path/to/model.gguf" 