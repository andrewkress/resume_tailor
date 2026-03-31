require "prawn"
require "prawndown"

class PdfGenerator
  def initialize(optimized_text)
    @optimized_text = Windows1252Sanitizer.call(optimized_text)
  end

  def generate
    Tempfile.new([ "optimized_resume", ".pdf" ]).tap do |file|
      file.binmode
      Prawn::Document.generate(file.path, overwrite_content: true) do |pdf|
        pdf.font_size 11
        pdf.markdown @optimized_text, leading: 4
      end
      file.rewind
    end
  end
end
