require "prawn"
require "prawndown"

class PdfGenerator
  def initialize(optimized_text, resume = nil)
    @optimized_text = optimized_text
    @resume = resume
  end

  def generate
    Tempfile.new([ "optimized_resume", ".pdf" ]).tap do |file|
      file.binmode
      Prawn::Document.generate(file.path, overwrite_content: true) do |pdf|
        if @resume&.company_name.present?
          # Add company header
          pdf.text "Job Application", align: :center, size: 16, bold: true
          pdf.line
          pdf.text @resume.company_name, align: :center, size: 14
          pdf.space 10
        end

        pdf.font_size 11
        pdf.markdown @optimized_text, leading: 4
      end
      file.rewind
    end
  end
end
