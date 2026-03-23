class OptimizeResumeJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    resume.update!(status: "processing")

    # 1. Extract text
    text = ResumeTextExtractor.new(resume.original_file).extract

    # 2. Optimize with Bedrock
    optimized_text = BedrockOptimizer.new(text, resume.job_description).optimize

    # 3. Generate PDF (pass resume to include company_name in header)
    pdf = PdfGenerator.new(optimized_text, resume).generate

    # 4. Save the optimized resume PDF
    optimized_resume = resume.optimized_resumes.create!
    optimized_resume.pdf.attach(io: pdf, filename: "_#{resume.company_name}_resume.pdf", content_type: "application/pdf")
    resume.update!(status: "completed")
  rescue => e
    resume&.update!(status: "failed")
    raise e
  end
end
