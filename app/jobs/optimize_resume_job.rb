class OptimizeResumeJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    resume.update!(status: "processing")

    # Check if user has a default resume to use
    default_resume = resume.user.default_resumes.find_by(status: "active")
    if default_resume
      # Use the default resume's markdown instead of extracting from new file
      text = default_resume.markdown
    else
      # 1. Extract text from uploaded file
      text = ResumeTextExtractor.new(resume.original_file).extract
    end

    # 2. Optimize with Bedrock
    optimized_text = BedrockOptimizer.new(text, resume.job_description).optimize

    # 3. Generate PDF
    pdf = PdfGenerator.new(optimized_text).generate

    # 4. Save the optimized resume PDF and markdown
    optimized_resume = resume.optimized_resumes.create!(
      markdown: optimized_text
    )
    optimized_resume.pdf.attach(io: pdf, filename: "#{user.first_name}#{user.last_name}_#{resume.company_name}_resume.pdf", content_type: "application/pdf")
    resume.update!(status: "completed")
  rescue => e
    resume&.update!(status: "failed")
    raise e
  end
end
