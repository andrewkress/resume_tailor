require "docx"
require "pdf/reader"
require "stringio"
require "tempfile"

class ResumeTextExtractor
  class UnsupportedFileTypeError < StandardError; end

  def initialize(file)
    @file = file
  end

  def extract
    case File.extname(filename).downcase
    when ".pdf"  then extract_from_pdf
    when ".docx" then extract_from_docx
    else
      raise UnsupportedFileTypeError, "Unsupported file type: #{filename}"
    end
  end

  private

  def filename
    @filename ||= if @file.respond_to?(:filename)
      @file.filename.to_s
    elsif @file.respond_to?(:original_filename)
      @file.original_filename.to_s
    else
      ""
    end
  end

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
