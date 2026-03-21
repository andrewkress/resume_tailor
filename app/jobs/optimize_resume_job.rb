class OptimizeResumeJob < ApplicationJob
  queue_as :default

  def perform(resume_id)
    resume = Resume.find(resume_id)
    resume.update!(status: 'processing')

    # 1. Extract text
    text = ResumeTextExtractor.new(resume.original_file).extract

    # 2. Optimize with Bedrock
    optimized_text = BedrockOptimizer.new(text, resume.job_description).optimize

    # 3. Generate PDF
    pdf_file = PdfGenerator.new(optimized_text).generate

    # 4. Upload to S3
    key = "optimized_resumes/#{resume.user_id}/#{resume.id}/optimized_#{Time.now.to_i}.pdf"
    result = S3Uploader.new(pdf_file, key).upload

    # 5. Save reference
    resume.optimized_resumes.create!(s3_url: result[:url], s3_key: result[:key])
    resume.update!(status: 'completed')
  rescue => e
    resume&.update!(status: 'failed')
    raise e
  end
end
