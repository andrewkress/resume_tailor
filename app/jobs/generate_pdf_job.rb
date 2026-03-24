class GeneratePdfJob < ApplicationJob
  queue_as :default

  def perform(optimized_resume_id)
    optimized_resume = OptimizedResume.find(optimized_resume_id)
    markdown = optimized_resume.markdown

    # Convert Markdown to HTML
    html_content = Kramdown::Document.new(markdown).to_html

    # Generate PDF from HTML
    pdf = WickedPdf.new.pdf_from_string(html_content)

    # Attach PDF to the optimized resume
    optimized_resume.pdf.attach(io: StringIO.new(pdf), filename: "optimized_resume_#{optimized_resume.id}.pdf", content_type: "application/pdf")
  end
end
