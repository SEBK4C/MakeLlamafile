# MakeLlamafile

A one-click converter for turning any model.GGUF or model.safetensors file into a self-contained executable with a web server interface. Built on Mozilla's llamafile technology for portable AI deployment.

![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Overview

MakeLlamafile simplifies the process of converting large language model files (GGUF or safetensors format) into standalone executables that can be run on any compatible system without installation. The resulting llamafile is a single-file executable that includes:

- The model weights
- A built-in web server with chat interface
- Command-line interface
- Cross-platform compatibility (macOS, Linux, Windows)

## Features

- Simple, guided user interface for converting models
- Automatic downloading of models from Hugging Face
- Customizable model parameters and settings
- Documentation generation for each converted model
- Optional testing of generated llamafiles
- Support for various model formats and types

## Requirements

### Supported Operating Systems
- macOS (intel and arm64)
- Ubuntu 22.04 and other Linux distributions
- Windows (with additional setup)

### Dependencies
- GNU make (gmake on some systems)
- sha256sum (or shasum on macOS)
- wget or curl
- unzip
- Cosmos bash shell (for Windows users)

## Installation

### Clone the Repository

```bash
git clone https://github.com/yourusername/MakeLlamafile.git
cd MakeLlamafile
```

### First Run

The script will automatically set up required dependencies on first run:

```bash
./setup.sh
```

This will:
1. Check and install required system dependencies
2. Clone and build Mozilla's llamafile project
3. Set up the necessary folder structure

## Usage

### Basic Usage

Convert a local GGUF file to a llamafile:

```bash
./create_llamafile.sh path/to/model.gguf
```

Convert a model from Hugging Face:

```bash
./create_llamafile.sh --huggingface organization/model-name
```

### Interactive Mode

Launch the interactive UI:

```bash
./create_llamafile.sh --interactive
```

### Options

```
Usage: ./create_llamafile.sh [OPTIONS] GGUF_FILE_OR_URL

Options:
  -h, --help                 Show this help message
  -o, --output-dir DIR       Set output directory (default: OUTPUT-LammaFile)
  -n, --name MODEL_NAME      Custom name for model (default: derived from filename)
  -d, --description DESC     Custom description for the model
  -t, --test                 Test the generated llamafile after creation
  -p, --prompt PROMPT        Test prompt to use with the model (default: 'Tell me a short story')
  -i, --interactive          Use interactive mode with guided UI
  --huggingface REPO         Download model from Hugging Face repository
```

## Using Generated Llamafiles

After creating a llamafile, you can run it directly:

### On macOS/Linux:

```bash
chmod +x output/model-name/model-name.llamafile
./output/model-name/model-name.llamafile
```

### On Windows:

Rename the file to add `.exe` extension, then double-click or run from command line.

Your web browser will open automatically to the chat interface (typically at http://localhost:8080).

## Project Structure

```
MakeLlamafile/
├── create_llamafile.sh      # Main script
├── setup.sh                 # Setup script
├── dependencies/            # External dependencies (git-ignored)
│   └── llamafile/           # Mozilla's llamafile repo
└── models/                  # Model storage
    ├── huggingface/         # Downloads from Hugging Face
    └── llamafiles/          # Generated llamafiles and output
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [Mozilla-Ocho/llamafile](https://github.com/Mozilla-Ocho/llamafile) - The underlying technology
- [llama.cpp](https://github.com/ggerganov/llama.cpp) - The backbone of llamafile
- Hugging Face - For hosting the model files
