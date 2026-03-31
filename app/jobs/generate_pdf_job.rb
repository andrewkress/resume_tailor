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
    optimized_resume.pdf.attach(
      io: pdf,
      filename: resume_filename_for(user, resume),
      content_type: "application/pdf"
    )

    resume.update!(status: "completed")
  rescue => e
    resume&.update!(status: "failed")
    raise e
  end

  private

  def resume_filename_for(user, resume)
    user_name = [ user.first_name, user.last_name ].compact_blank.join("_").parameterize(separator: "_")
    company_name = resume.company_name.to_s.parameterize(separator: "_")
    [ user_name.presence || "user", company_name.presence || "general", "resume.pdf" ].join("_")
  end
end
