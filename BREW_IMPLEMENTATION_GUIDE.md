# MakeLlamafile Homebrew Tap Implementation Guide

This document provides a step-by-step guide for developing the Homebrew tap for MakeLlamafile, including a todo list and comprehensive testing procedures.

## Todo List

### 1. Repository Setup

- [ ] Create GitHub repository named `homebrew-makelamafile`
- [ ] Initialize with README.md, LICENSE (MIT), and .gitignore
- [ ] Clone repository locally
- [ ] Create directory structure:
  ```
  homebrew-makelamafile/
  ├── Formula/
  │   └── makelamafile.rb
  ├── README.md
  ├── LICENSE
  └── .gitignore
  ```

### 2. Formula Development

- [ ] Create basic formula skeleton in `Formula/makelamafile.rb`
- [ ] Define proper class name, description, and homepage
- [ ] Prepare initial release package:
  - [ ] Tag MakeLlamafile repository with version (e.g., v1.0.0)
  - [ ] Create proper release tarball
  - [ ] Calculate SHA256 hash of the tarball
  - [ ] Update formula with URL and SHA256
- [ ] Define dependencies:
  - [ ] make/gmake
  - [ ] curl/wget
  - [ ] coreutils (for sha256sum on macOS)
  - [ ] git (for cloning Mozilla's llamafile)
- [ ] Implement installation logic:
  - [ ] Directory creation
  - [ ] Llamafile repository clone & build
  - [ ] Script installation
  - [ ] Binary installation
  - [ ] Configuration setup
- [ ] Create basic test function in the formula

### 3. Local Testing

- [ ] Set up local tap:
  ```bash
  brew tap-new sebk4c/makelamafile --no-git
  cp Formula/makelamafile.rb $(brew --repository)/Library/Taps/sebk4c/homebrew-makelamafile/Formula/
  ```
- [ ] Test installation from local tap:
  ```bash
  brew install --verbose --debug sebk4c/makelamafile/makelamafile
  ```
- [ ] Verify installation structure:
  - [ ] Check binary locations
  - [ ] Check directory structure
  - [ ] Verify permissions
- [ ] Test basic functionality:
  - [ ] Help command
  - [ ] Directory creation
  - [ ] Small model conversion

### 4. Publish and Distribution

- [ ] Push repository to GitHub as `homebrew-makelamafile`
- [ ] Test tap installation from GitHub:
  ```bash
  brew tap sebk4c/makelamafile
  brew install makelamafile
  ```
- [ ] Create documentation in tap repository:
  - [ ] Installation instructions
  - [ ] Usage examples
  - [ ] Troubleshooting tips
- [ ] Set up version update workflow

## Testing Guide

### Unit Tests

These tests verify individual components of the formula:

1. **Dependency Installation Test**
   ```ruby
   test do
     # Verify dependencies are installed and working
     system "which", "shasum"
     system "which", "curl"
     system "which", "make"
   end
   ```

2. **Script Execution Test**
   ```ruby
   test do
     # Test if the script runs without errors
     assert_match "Usage:", shell_output("#{bin}/makelamafile --help")
   end
   ```

3. **Directory Structure Test**
   ```ruby
   test do
     # Verify required directories exist
     assert_predicate "#{HOMEBREW_PREFIX}/share/makelamafile/models/llamafiles", :directory?
     assert_predicate "#{HOMEBREW_PREFIX}/share/makelamafile/models/huggingface", :directory?
   end
   ```

### Integration Tests

For more comprehensive testing, create a separate test script:

```bash
#!/bin/bash
set -e

# Test script for MakeLlamafile
echo "Testing MakeLlamafile installation..."

# 1. Verify all commands are available
which makelamafile
which llamafile
which zipalign

# 2. Create test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# 3. Download a tiny test model (5-10MB)
echo "Downloading tiny test model..."
curl -L https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf -o test_model.gguf

# 4. Convert the model
echo "Converting model to llamafile..."
makelamafile test_model.gguf

# 5. Verify llamafile creation
test -f models/llamafiles/test_model/test_model.llamafile || { echo "Failed to create llamafile"; exit 1; }
chmod +x models/llamafiles/test_model/test_model.llamafile

# 6. Run a quick test with the llamafile
echo "Testing the generated llamafile..."
models/llamafiles/test_model/test_model.llamafile -e -p "Hello" -n 10

# 7. Clean up
cd
rm -rf "$TEST_DIR"
echo "Tests completed successfully!"
```

### Platform-Specific Tests

#### macOS Testing

- [ ] Test on Intel Mac (x86_64)
- [ ] Test on Apple Silicon Mac (arm64)
- [ ] Verify PATH and permissions
- [ ] Test with different macOS versions if possible

#### Linux Testing

- [ ] Test on Ubuntu (latest LTS)
- [ ] Test on other distributions via Homebrew on Linux
- [ ] Verify library dependencies

### Manual End-to-End Tests

These tests should be performed manually before each release:

1. **Fresh Installation Test**
   - Start with a clean environment (Docker container recommended)
   - Install tap and formula
   - Verify all components are installed correctly

2. **Model Conversion Test**
   - Test with multiple model types:
     - Small GGUF model (<1GB)
     - Medium GGUF model (1-7GB)
     - Large GGUF model (>7GB)
   - Test with safetensors format if supported

3. **Update Test**
   - Install an older version
   - Update to the newest version
   - Verify all functionality works after update

## Implementation Notes

### Formula Structure

The formula should have this general structure:

```ruby
class MakeLlamafile < Formula
  desc "Converter for turning LLM files into self-contained executables"
  homepage "https://github.com/yourusername/MakeLlamafile"
  url "https://github.com/yourusername/MakeLlamafile/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  license "MIT"
  
  # Dependencies
  depends_on "make" => :build
  depends_on "curl"
  depends_on "coreutils" # For sha256sum on macOS
  depends_on "git" # For cloning Mozilla's llamafile
  
  def install
    # Create directories
    mkdir_p "#{share}/makelamafile/models/huggingface"
    mkdir_p "#{share}/makelamafile/models/llamafiles"
    
    # Clone and build Mozilla llamafile
    system "git", "clone", "https://github.com/Mozilla-Ocho/llamafile.git", "dependencies/llamafile"
    cd "dependencies/llamafile" do
      system "make", "-j#{ENV.make_jobs}"
    end
    
    # Install scripts
    bin.install "create_llamafile.sh" => "makelamafile"
    bin.install "setup.sh"
    
    # Install binaries
    bin.install "dependencies/llamafile/o/llamafile"
    bin.install "dependencies/llamafile/o/zipalign"
    
    # Create configuration file pointing to the shared directory
    (etc/"makelamafile").write <<~EOS
      OUTPUT_DIR="#{share}/makelamafile/models/llamafiles"
      DOWNLOAD_DIR="#{share}/makelamafile/models/huggingface"
    EOS
  end
  
  def post_install
    # Ensure directories have correct permissions
    chmod 0755, "#{share}/makelamafile/models/huggingface"
    chmod 0755, "#{share}/makelamafile/models/llamafiles"
  end
  
  def caveats
    <<~EOS
      MakeLlamafile has been installed!
      
      To convert a model file to a llamafile:
        makelamafile path/to/model.gguf
      
      Output will be saved to:
        #{share}/makelamafile/models/llamafiles
    EOS
  end
  
  test do
    # Basic check that the executable runs
    assert_match "Usage:", shell_output("#{bin}/makelamafile --help")
    
    # Check if the directories exist
    assert_predicate "#{share}/makelamafile/models/llamafiles", :directory?
    assert_predicate "#{share}/makelamafile/models/huggingface", :directory?
  end
end
```

### Handling Different Platforms

The formula needs to account for platform differences:

1. **macOS Specifics:**
   - Use `shasum` instead of `sha256sum`
   - Handle different architectures (Intel vs Apple Silicon)

2. **Linux Specifics:**
   - Ensure all dependencies are available
   - Test with different distributions

## Reasoning Behind Implementation Choices

1. **Directory Structure:**
   - We use `#{share}/makelamafile` for data rather than `#{var}` because these are not variable/changing data but rather shared resources
   - Models are placed in standardized locations for consistency

2. **Configuration Management:**
   - Using a configuration file in `#{etc}` allows users to find and modify settings
   - Default directories point to Homebrew-managed locations

3. **Building llamafile from source:**
   - This ensures compatibility with the user's system
   - Allows for optimizations specific to the architecture

4. **Permission management:**
   - Explicitly setting permissions ensures users can write to model directories
   - The `post_install` hook ensures these permissions are set correctly

5. **Testing approach:**
   - Basic tests verify installation correctness
   - More extensive tests require downloading actual models and are kept external

## Troubleshooting Common Issues

Include these sections in your documentation:

1. **Installation Failed:**
   - Check for missing dependencies
   - Verify disk space
   - Ensure proper permissions

2. **Model Conversion Fails:**
   - Verify model format
   - Check disk space for large models
   - Look for error messages in logs

3. **Llamafile Not Running:**
   - Check executable permissions
   - Verify architecture compatibility
   - Check system resources (RAM, disk) 