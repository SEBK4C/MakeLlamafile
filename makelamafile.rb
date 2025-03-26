class MakeLlamafile < Formula
  desc "Converter for turning LLM files into self-contained executables on macOS"
  homepage "https://github.com/sebk4c/MakeLlamafile"
  url "https://github.com/sebk4c/MakeLlamafile/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  license "MIT"
  
  depends_on "curl"
  depends_on :macos => :monterey
  depends_on :arch => :arm64
  
  def install
    # Install scripts
    bin.install "create_llamafile.sh" => "makelamafile"
    
    # Create package-specific directories in the Homebrew prefix
    share_path = "#{prefix}/share/makelamafile"
    mkdir_p "#{share_path}/bin"
    
    # Download binaries for llamafile tools
    system "curl", "-L", "-o", "#{share_path}/bin/llamafile", "https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.1/llamafile-0.9.1"
    system "curl", "-L", "-o", "#{share_path}/bin/zipalign", "https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.1/zipalign-0.9.1"
    chmod 0755, "#{share_path}/bin/llamafile"
    chmod 0755, "#{share_path}/bin/zipalign"
    
    # Create symlinks in bin directory
    bin.install_symlink "#{share_path}/bin/llamafile"
    bin.install_symlink "#{share_path}/bin/zipalign"
    
    # Copy setup script to share directory
    share_path.install "setup.sh"
    
    # Copy README and other documentation
    doc.install "README.md"
    doc.install "LICENSE"
  end
  
  def post_install
    # Create user directories
    user_home = ENV["HOME"]
    models_dir = "#{user_home}/models"
    config_dir = "#{user_home}/.config/makelamafile"
    
    system "mkdir", "-p", "#{models_dir}/huggingface"
    system "mkdir", "-p", "#{models_dir}/llamafiles"
    system "mkdir", "-p", config_dir
    
    # Create configuration file
    File.write("#{config_dir}/config", <<~EOS)
      # MakeLlamafile configuration
      OUTPUT_DIR="#{models_dir}/llamafiles"
      DOWNLOAD_DIR="#{models_dir}/huggingface"
      BIN_DIR="#{prefix}/share/makelamafile/bin"
    EOS
    
    # Ensure directories have correct permissions
    system "chmod", "755", "#{models_dir}/huggingface"
    system "chmod", "755", "#{models_dir}/llamafiles"
    system "chmod", "644", "#{config_dir}/config"
  end
  
  def caveats
    user_home = ENV["HOME"]
    
    <<~EOS
      MakeLlamafile has been installed!
      
      To convert a model file to a llamafile:
        makelamafile path/to/model.gguf
      
      Output will be saved to:
        #{user_home}/models/llamafiles
      
      Downloaded models will be stored in:
        #{user_home}/models/huggingface
      
      For more information, run:
        makelamafile --help
      
      Note: This version is optimized for macOS on Apple Silicon (M1/M2/M3).
    EOS
  end
  
  test do
    # Basic check that the executable runs
    assert_match "Usage:", shell_output("#{bin}/makelamafile --help")
    
    # Check if the user's directories exist
    user_home = ENV["HOME"]
    assert_predicate "#{user_home}/models/llamafiles", :directory?
    assert_predicate "#{user_home}/models/huggingface", :directory?
    
    # Check if required binaries are available
    assert_predicate bin/"llamafile", :executable?
    assert_predicate bin/"zipalign", :executable?
  end
end 