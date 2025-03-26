class MakeLlamafile < Formula
  desc "Converter for turning LLM files into self-contained executables"
  homepage "https://github.com/yourusername/MakeLlamafile"
  url "https://github.com/yourusername/MakeLlamafile/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  license "MIT"
  
  depends_on "make" => :build
  depends_on "curl"
  depends_on "coreutils" # For sha256sum on macOS
  depends_on "git" # For cloning Mozilla's llamafile
  
  def install
    # Create directories
    mkdir_p "#{share}/makelamafile/models/huggingface"
    mkdir_p "#{share}/makelamafile/models/llamafiles"
    
    # Clone and build Mozilla llamafile
    system "git", "clone", "--depth", "1", "https://github.com/Mozilla-Ocho/llamafile.git", "dependencies/llamafile"
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
    (etc/"makelamafile").mkpath
    (etc/"makelamafile/config").write <<~EOS
      OUTPUT_DIR="#{share}/makelamafile/models/llamafiles"
      DOWNLOAD_DIR="#{share}/makelamafile/models/huggingface"
    EOS
    
    # Copy README and other documentation
    doc.install "README.md"
    doc.install "LICENSE"
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
      
      For more information, run:
        makelamafile --help
    EOS
  end
  
  test do
    # Basic check that the executable runs
    assert_match "Usage:", shell_output("#{bin}/makelamafile --help")
    
    # Check if the directories exist
    assert_predicate "#{share}/makelamafile/models/llamafiles", :directory?
    assert_predicate "#{share}/makelamafile/models/huggingface", :directory?
    
    # Check if required binaries are available
    assert_predicate bin/"llamafile", :executable?
    assert_predicate bin/"zipalign", :executable?
  end
end 