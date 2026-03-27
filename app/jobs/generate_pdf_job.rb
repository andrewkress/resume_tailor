class GeneratePdfJob < ApplicationJob
  queue_as :default

  def perform(optimized_resume_id)
    optimized_resume = OptimizedResume.find(optimized_resume_id)
    resume = optimized_resume.resume
    user = resume.user
    resume.update!(status: "processing")

    # Generate PDF from Markdown
    pdf = PdfGenerator.new(optimized_resume.markdown).generate

    # Attach PDF to the optimized resume
    optimized_resume.pdf.attach(io: pdf, filename: "#{user.first_name}#{user.last_name}_#{resume.company_name}_resume.pdf", content_type: "application/pdf")

    resume.update!(status: "completed")
  rescue => e
    resume&.update!(status: "failed")
    raise e
  end
end
