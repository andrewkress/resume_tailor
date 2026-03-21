class ResumeTextExtractor
  def initialize(file)
    @file = file
  end

  def extract
    case File.extname(@file.filename.to_s).downcase
    when ".pdf"  then extract_from_pdf
    when ".docx" then extract_from_docx
    else raise "Unsupported file type"
    end
  end

  private

  def extract_from_pdf
    io = StringIO.new(@file.download)
    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n")
  end

  def extract_from_docx
    # Write to temp file since docx gem needs a path
    Tempfile.create([ "resume", ".docx" ]) do |tmp|
      tmp.binmode
      tmp.write(@file.download)
      tmp.flush
      doc = Docx::Document.open(tmp.path)
      doc.paragraphs.map(&:to_s).join("\n")
    end
  end
end
