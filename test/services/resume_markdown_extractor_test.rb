require "test_helper"

class ResumeMarkdownExtractorTest < ActiveSupport::TestCase
  test "formats extracted text into markdown with the ruby formatter by default" do
    with_env("AWS_REGION", nil) do
      text_extractor = stub(new: stub(extract: "Jane Doe\nEXPERIENCE\n- Shipped features"))
      formatter = stub(new: stub(format: "# Jane Doe\n\n## Experience\n- Shipped features"))
      ai_formatter = stub(new: stub(format: "# AI Markdown"))

      markdown = ResumeMarkdownExtractor.new(
        Object.new,
        text_extractor: text_extractor,
        formatter: formatter,
        ai_formatter: ai_formatter
      ).extract

      assert_equal "# Jane Doe\n\n## Experience\n- Shipped features", markdown
    end
  end

  test "uses haiku to format extracted text when ai is available" do
    with_env("AWS_REGION", "us-east-1") do
      text_extractor = stub(new: stub(extract: "Jane Doe\nEXPERIENCE\nBuilt features"))
      formatter = stub(new: stub(format: "# Jane Doe"))
      ai_formatter = stub(new: stub(format: "# Jane Doe\n\n## Experience\n- Led projects"))

      markdown = ResumeMarkdownExtractor.new(
        Object.new,
        text_extractor: text_extractor,
        formatter: formatter,
        ai_formatter: ai_formatter
      ).extract

      assert_equal "# Jane Doe\n\n## Experience\n- Led projects", markdown
    end
  end

  test "falls back to ruby formatter if ai formatting raises" do
    with_env("AWS_REGION", "us-east-1") do
      text_extractor = stub(new: stub(extract: "Jane Doe"))
      formatter_instance = stub(format: "# Jane Doe")
      formatter = stub(new: formatter_instance)
      ai_formatter = stub(new: failing_formatter)

      markdown = ResumeMarkdownExtractor.new(
        Object.new,
        text_extractor: text_extractor,
        formatter: formatter,
        ai_formatter: ai_formatter
      ).extract

      assert_equal "# Jane Doe", markdown
    end
  end

  private

  def with_env(key, value)
    previous_value = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = previous_value
  end

  def failing_formatter
    Class.new do
      def format
        raise "bedrock unavailable"
      end
    end.new
  end
end
