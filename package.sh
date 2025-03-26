#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_NAME="MakeLlamafile"
TAR_NAME="${REPO_NAME}-${VERSION}"
OUTPUT_DIR="$SCRIPT_DIR/dist"

echo -e "${YELLOW}Packaging MakeLlamafile v${VERSION} for Homebrew release${NC}"

# --------------------------------------
# Step 1: Run tests
# --------------------------------------
echo -e "\n${YELLOW}Step 1: Running tests...${NC}"
if [ -f "$SCRIPT_DIR/test.sh" ]; then
  bash "$SCRIPT_DIR/test.sh"
else
  echo -e "${RED}❌ test.sh not found${NC}"
  exit 1
fi

# --------------------------------------
# Step 2: Create distribution directory
# --------------------------------------
echo -e "\n${YELLOW}Step 2: Creating distribution directory...${NC}"
mkdir -p "$OUTPUT_DIR"

# --------------------------------------
# Step 3: Create tarball
# --------------------------------------
echo -e "\n${YELLOW}Step 3: Creating tarball...${NC}"

# Create a temporary directory for packaging
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="$TEMP_DIR/$TAR_NAME"
mkdir -p "$PACKAGE_DIR"

# Copy essential files
echo "Copying files to package directory..."
cp -v "$SCRIPT_DIR/create_llamafile.sh" "$PACKAGE_DIR/"
cp -v "$SCRIPT_DIR/setup.sh" "$PACKAGE_DIR/"
cp -v "$SCRIPT_DIR/README.md" "$PACKAGE_DIR/"
cp -v "$SCRIPT_DIR/LICENSE" "$PACKAGE_DIR/"
cp -v "$SCRIPT_DIR/makelamafile.rb" "$PACKAGE_DIR/"

# Create directory structure
mkdir -p "$PACKAGE_DIR/models/huggingface"
mkdir -p "$PACKAGE_DIR/models/llamafiles"

# Create tarball
echo "Creating tarball..."
cd "$TEMP_DIR"
tar -czf "$OUTPUT_DIR/$TAR_NAME.tar.gz" "$TAR_NAME"
cd "$SCRIPT_DIR"

# --------------------------------------
# Step 4: Calculate SHA256 hash
# --------------------------------------
echo -e "\n${YELLOW}Step 4: Calculating SHA256 hash...${NC}"
if command -v shasum &> /dev/null; then
  SHA256=$(shasum -a 256 "$OUTPUT_DIR/$TAR_NAME.tar.gz" | cut -d ' ' -f 1)
elif command -v sha256sum &> /dev/null; then
  SHA256=$(sha256sum "$OUTPUT_DIR/$TAR_NAME.tar.gz" | cut -d ' ' -f 1)
else
  echo -e "${RED}❌ Cannot calculate SHA256 hash: neither shasum nor sha256sum available${NC}"
  exit 1
fi

echo "SHA256: $SHA256"

# --------------------------------------
# Step 5: Update formula with SHA256
# --------------------------------------
echo -e "\n${YELLOW}Step 5: Updating formula with correct SHA256...${NC}"
sed -i.bak "s/sha256 \"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"/sha256 \"$SHA256\"/" "$SCRIPT_DIR/makelamafile.rb"
rm -f "$SCRIPT_DIR/makelamafile.rb.bak"

# --------------------------------------
# Step 6: Create Homebrew tap directory
# --------------------------------------
echo -e "\n${YELLOW}Step 6: Creating Homebrew tap directory...${NC}"
mkdir -p "$OUTPUT_DIR/homebrew-makelamafile/Formula"
cp -v "$SCRIPT_DIR/makelamafile.rb" "$OUTPUT_DIR/homebrew-makelamafile/Formula/"

# Create a README for the tap
cat > "$OUTPUT_DIR/homebrew-makelamafile/README.md" << EOF
# Homebrew Tap for MakeLlamafile

This repository contains the Homebrew formula for [MakeLlamafile](https://github.com/sebk4c/MakeLlamafile), a tool for converting LLM files into self-contained executables using Mozilla's llamafile technology.

## Installation

To install MakeLlamafile using Homebrew:

\`\`\`bash
brew tap sebk4c/makelamafile
brew install makelamafile
\`\`\`

## Usage

After installation, you can convert model files to llamafiles:

\`\`\`bash
makelamafile path/to/model.gguf
\`\`\`

For more information, run:

\`\`\`bash
makelamafile --help
\`\`\`

## License

MakeLlamafile is distributed under the MIT License.
EOF

# --------------------------------------
# Step 7: Clean up
# --------------------------------------
echo -e "\n${YELLOW}Step 7: Cleaning up...${NC}"
rm -rf "$TEMP_DIR"

# --------------------------------------
# Final output
# --------------------------------------
echo -e "\n${GREEN}Packaging complete!${NC}"
echo -e "Tarball: ${OUTPUT_DIR}/${TAR_NAME}.tar.gz"
echo -e "SHA256: ${SHA256}"
echo -e "Homebrew tap: ${OUTPUT_DIR}/homebrew-makelamafile"
echo ""
echo -e "Next steps:"
echo -e "1. Tag a release in your GitHub repository:"
echo -e "   git tag v${VERSION}"
echo -e "   git push origin v${VERSION}"
echo -e ""
echo -e "2. Upload the tarball to the GitHub release"
echo -e ""
echo -e "3. Create a new GitHub repository named 'homebrew-makelamafile'"
echo -e "   and push the contents of ${OUTPUT_DIR}/homebrew-makelamafile"
echo -e ""
echo -e "4. Users can then install with:"
echo -e "   brew tap sebk4c/makelamafile"
echo -e "   brew install makelamafile" 