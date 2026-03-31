class OptimizeResumeJob < ApplicationJob
  queue_as :default

  def perform(resume_id, model)
    resume = Resume.find(resume_id)
    user = resume.user
    resume.update!(status: "processing")

    text = ResumeTextExtractor.new(resume.original_file).extract

    optimizer = BedrockOptimizer.new(text, resume.job_description, model)
    optimized_text = optimizer.optimize

    pdf = PdfGenerator.new(optimized_text).generate

    optimized_resume = resume.optimized_resumes.create!(
      markdown: optimized_text,
      model_used: optimizer.model_name
    )
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
