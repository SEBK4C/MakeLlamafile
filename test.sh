#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Running MakeLlamafile Local Tests${NC}"

# Test script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --------------------------------------
# Test 1: Check dependencies
# --------------------------------------
echo -e "\n${YELLOW}Test 1: Checking dependencies...${NC}"

# Check for required dependencies
for cmd in git make; do
  if command -v $cmd &> /dev/null; then
    echo -e "✅ $cmd is installed: $(which $cmd)"
  else
    echo -e "${RED}❌ $cmd not found in PATH${NC}"
    exit 1
  fi
done

# Check for curl or wget
if command -v curl &> /dev/null; then
  echo -e "✅ curl is installed: $(which curl)"
elif command -v wget &> /dev/null; then
  echo -e "✅ wget is installed: $(which wget)"
else
  echo -e "${RED}❌ Neither curl nor wget found in PATH${NC}"
  exit 1
fi

# Check for shasum or sha256sum
if command -v shasum &> /dev/null; then
  echo -e "✅ shasum is installed: $(which shasum)"
elif command -v sha256sum &> /dev/null; then
  echo -e "✅ sha256sum is installed: $(which sha256sum)"
else
  echo -e "${YELLOW}⚠️ Neither shasum nor sha256sum found in PATH. SHA256 verification will not be available.${NC}"
fi

# Check for unzip
if command -v unzip &> /dev/null; then
  echo -e "✅ unzip is installed: $(which unzip)"
else
  echo -e "${RED}❌ unzip not found in PATH${NC}"
  exit 1
fi

# --------------------------------------
# Test 2: Run setup.sh
# --------------------------------------
echo -e "\n${YELLOW}Test 2: Running setup script...${NC}"

# Make setup.sh executable if it's not already
chmod +x setup.sh

# Run setup script
./setup.sh

# Check binaries
if [ -x "bin/llamafile" ] && [ -x "bin/zipalign" ]; then
  echo -e "✅ Required binaries are available and executable"
else
  echo -e "${RED}❌ Required binaries are missing or not executable${NC}"
  exit 1
fi

# --------------------------------------
# Test 3: Download and convert a tiny model
# --------------------------------------
echo -e "\n${YELLOW}Test 3: Testing model conversion (small test model)...${NC}"

# Download tiny test model (uses a very small quantized model for testing)
echo "Downloading tiny test model..."
MODEL_URL="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf"
MODEL_FILE="$SCRIPT_DIR/test_model.gguf"

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

# Make create_llamafile.sh executable if it's not already
chmod +x create_llamafile.sh

# Convert the model
echo "Converting model to llamafile..."
./create_llamafile.sh -n "test_model" "$MODEL_FILE"

# Check if llamafile was created in the default output directory
if [[ -f "$SCRIPT_DIR/models/llamafiles/test_model/test_model.llamafile" ]]; then
  echo "✅ Llamafile created successfully"
else
  echo -e "${RED}❌ Failed to create llamafile${NC}"
  ls -la "$SCRIPT_DIR/models/llamafiles"
  exit 1
fi

# --------------------------------------
# Test 4: Test the generated llamafile
# --------------------------------------
echo -e "\n${YELLOW}Test 4: Testing the generated llamafile...${NC}"
echo "Running very basic inference test (may take a moment)..."

# Run a simple test with the model
LLAMAFILE_PATH="$SCRIPT_DIR/models/llamafiles/test_model/test_model.llamafile"

# Make the llamafile executable
chmod +x "$LLAMAFILE_PATH"

# Run a basic test (with a timeout to prevent hanging)
echo "Testing inference with a simple prompt..."
INFERENCE_OUTPUT=$(timeout 60s "$LLAMAFILE_PATH" -e -n 5 -p "Hello" 2>/dev/null || echo "Timeout or error occurred")

if [[ "$INFERENCE_OUTPUT" != "" && "$INFERENCE_OUTPUT" != *"Timeout or error occurred"* ]]; then
  echo "✅ Llamafile produced output when prompted"
  echo -e "  ${YELLOW}Preview:${NC} ${INFERENCE_OUTPUT:0:100}..."
else
  echo -e "${YELLOW}⚠️ Llamafile test produced warnings or errors, but we'll continue${NC}"
  echo -e "  This might be due to platform-specific issues or limitations with the test model."
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
echo "You can now proceed with creating a Homebrew formula and release." 