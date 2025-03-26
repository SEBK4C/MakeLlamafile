# Installing MakeLlamafile via Homebrew

This document explains the correct process for installing MakeLlamafile using Homebrew, including the steps Homebrew takes and how to troubleshoot common issues.

## Correct Installation Commands

To install MakeLlamafile via Homebrew, use the following commands:

```bash
# Add the tap repository
brew tap sebk4c/makellamafile

# Install the formula
brew install makellamafile
```

## What Happens During Installation

When you run these commands, Homebrew performs the following steps:

1. **Tap Repository Cloning**:
   - Clones `https://github.com/sebk4c/homebrew-makellamafile` to your local Homebrew taps directory
   - This repository must exist on GitHub with proper formula files

2. **Formula Parsing**:
   - Reads the Ruby formula file for `makellamafile`
   - Analyzes dependencies and installation requirements

3. **Dependency Installation**:
   - Installs required dependencies (curl, etc.)
   - Verifies system requirements (macOS version, architecture)

4. **Software Download**:
   - Downloads Mozilla's llamafile binaries
   - Retrieves a small test model for verification

5. **Installation to Homebrew Directories**:
   - Installs scripts to `$(brew --prefix)/bin/`
   - Creates directories in `$(brew --prefix)/share/makellamafile/`
   - Sets up documentation in `$(brew --prefix)/share/doc/makellamafile/`

6. **User Configuration Setup**:
   - Creates directories in `$HOME/models/`
   - Sets up configuration in `$HOME/.config/makellamafile/`
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
Cloning into '/opt/homebrew/Library/Taps/sebk4c/homebrew-makellamafile'...
remote: Repository not found.
fatal: repository 'https://github.com/sebk4c/homebrew-makellamafile/' not found
```

**Problem**: The repository doesn't exist on GitHub.

**Solution**: For Homebrew taps, you need a GitHub repository with a specific naming convention:

1. The GitHub repository must be named `homebrew-makellamafile` (note the prefix "homebrew-")
2. The tap command is `brew tap sebk4c/makellamafile` (without the "homebrew-" prefix)

### GitHub Repository Naming Convention

Homebrew has a specific naming convention for tap repositories:

1. Create a GitHub repository with name: `homebrew-makellamafile`
2. Inside this repository, create a directory structure with:
   ```
   Formula/
     makellamafile.rb
   ```
3. When users run `brew tap sebk4c/makellamafile`, Homebrew looks for:
   `https://github.com/sebk4c/homebrew-makellamafile`

This follows Homebrew's standard convention where:
- GitHub repo name: `homebrew-foo`
- Tap command: `brew tap username/foo`

### Formula-Specific Issues

If installation fails even with the correct repository:

1. Check Homebrew logs:
   ```bash
   brew install --verbose makellamafile
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
   makellamafile --help
   ```

2. Convert a GGUF model:
   ```bash
   makellamafile path/to/model.gguf
   ```

3. Run the pre-converted test model:
   ```bash
   ~/models/llamafiles/TinyLLama-v0.1-5M-F16/TinyLLama-v0.1-5M-F16.llamafile
   ```

Converted models will be stored in `~/models/llamafiles/` by default. 