class ResumeMarkdownExtractor
  def initialize(file, text_extractor: ResumeTextExtractor, formatter: ResumeMarkdownFormatter, ai_formatter: BedrockResumeMarkdownFormatter)
    @file = file
    @text_extractor = text_extractor
    @formatter = formatter
    @ai_formatter = ai_formatter
  end

  def extract
    text = @text_extractor.new(@file).extract

    return @ai_formatter.new(text).format if ai_available?

    @formatter.new(text).format
  rescue => e
    Rails.logger.warn("ResumeMarkdownExtractor fallback triggered: #{e.message}") if defined?(Rails)
    @formatter.new(text).format
  end

  private

  def ai_available?
    ENV["AWS_REGION"].present?
  end
end
