class OptimizeResumeJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    resume.update!(status: "processing")

    # 1. Extract text
    text = ResumeTextExtractor.new(resume.original_file).extract

    # 2. Optimize with Bedrock
    optimized_text = BedrockOptimizer.new(text, resume.job_description).optimize

    # 3. Generate PDF
    pdf = PdfGenerator.new(optimized_text).generate

    # 4. Save the optimized resume PDF
    optimized_resume = resume.optimized_resumes.create!
    debugger
    optimized_resume.pdf.attach(io: pdf, filename: "optimized_resume.pdf", content_type: "application/pdf")
    resume.update!(status: "completed")
  rescue => e
    resume&.update!(status: "failed")
    raise e
  end
end
