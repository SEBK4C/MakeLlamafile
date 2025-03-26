# Installing MakeLlamafile via Homebrew

This document explains the correct process for installing MakeLlamafile using Homebrew, including the steps Homebrew takes and how to troubleshoot common issues.

## Correct Installation Commands

To install MakeLlamafile via Homebrew, use the following commands:

```bash
# Add the tap repository
brew tap sebk4c/makelamafile

# Install the formula
brew install makelamafile
```

## What Happens During Installation

When you run these commands, Homebrew performs the following steps:

1. **Tap Repository Cloning**:
   - Clones `https://github.com/sebk4c/homebrew-makelamafile` to your local Homebrew taps directory
   - This repository must exist on GitHub with proper formula files

2. **Formula Parsing**:
   - Reads the Ruby formula file for `makelamafile`
   - Analyzes dependencies and installation requirements

3. **Dependency Installation**:
   - Installs required dependencies (curl, etc.)
   - Verifies system requirements (macOS version, architecture)

4. **Software Download**:
   - Downloads Mozilla's llamafile binaries
   - Retrieves a small test model for verification

5. **Installation to Homebrew Directories**:
   - Installs scripts to `$(brew --prefix)/bin/`
   - Creates directories in `$(brew --prefix)/share/makelamafile/`
   - Sets up documentation in `$(brew --prefix)/share/doc/makelamafile/`

6. **User Configuration Setup**:
   - Creates directories in `$HOME/models/`
   - Sets up configuration in `$HOME/.config/makelamafile/`
   - Pre-converts a test model so it's immediately usable

7. **Permission Setting**:
   - Makes binaries executable
   - Sets appropriate permissions on directories

8. **Installation Testing**:
   - Runs tests to verify the installation works properly

## Troubleshooting Installation Issues

### Repository Not Found Error

If you see an error like:
```
Cloning into '/opt/homebrew/Library/Taps/sebk4c/homebrew-tap'...
remote: Repository not found.
fatal: repository 'https://github.com/sebk4c/homebrew-tap/' not found
```

**Problem**: Homebrew is looking for the wrong repository URL.

**Solution**: The correct command should use `sebk4c/makelamafile`, not `sebk4c/tap`:
```bash
brew tap sebk4c/makelamafile
brew install makelamafile
```

This looks for a repository at `https://github.com/sebk4c/homebrew-makelamafile`.

### Missing Repositories

If the repository `sebk4c/homebrew-makelamafile` doesn't exist yet:

1. It needs to be created on GitHub with:
   - Repository name: `homebrew-makelamafile`
   - Formula file: `Formula/makelamafile.rb`

2. The formula should point to a valid release of the MakeLlamafile project.

### Formula-Specific Issues

If installation fails even with the correct repository:

1. Check Homebrew logs:
   ```bash
   brew install --verbose makelamafile
   ```

2. Verify your system meets the requirements:
   - macOS Monterey or later
   - Apple Silicon (M1/M2/M3) architecture

3. Ensure you have enough disk space:
   - At least 200MB for the basic installation
   - Additional space for models (varies by model size)

## After Installation

Once installed, you can:

1. Run the help command:
   ```bash
   makelamafile --help
   ```

2. Convert a GGUF model:
   ```bash
   makelamafile path/to/model.gguf
   ```

3. Run the pre-converted test model:
   ```bash
   ~/models/llamafiles/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile
   ```

Converted models will be stored in `~/models/llamafiles/` by default. 