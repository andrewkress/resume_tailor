class ResumeMarkdownExtractor
  def initialize(file, text_extractor: ResumeTextExtractor, formatter: ResumeMarkdownFormatter, ai_formatter: BedrockResumeMarkdownFormatter)
    @file = file
    @text_extractor = text_extractor
    @formatter = formatter
    @ai_formatter = ai_formatter
  end

  def extract
    text = @text_extractor.new(@file).extract
    markdown = @formatter.new(text).format

    return markdown unless should_use_ai_fallback?(markdown)

    @ai_formatter.new(text).format
  rescue => e
    Rails.logger.warn("ResumeMarkdownExtractor fallback triggered: #{e.message}") if defined?(Rails)
    @formatter.new(text).format
  end

  private

  def should_use_ai_fallback?(markdown)
    ai_available? && markdown.length < 200
  end

  def ai_available?
    ENV["AWS_REGION"].present?
  end
end
