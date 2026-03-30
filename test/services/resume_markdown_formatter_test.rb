require "test_helper"

class ResumeMarkdownFormatterTest < ActiveSupport::TestCase
  test "formats a plain text resume into basic markdown" do
    text = <<~TEXT
      Jane Doe
      jane@example.com
      EXPERIENCE
      • Built features for a Rails app
      • Improved test coverage
      EDUCATION:
      State University
    TEXT

    markdown = ResumeMarkdownFormatter.new(text).format

    assert_includes markdown, "# Jane Doe"
    assert_includes markdown, "## Experience"
    assert_includes markdown, "- Built features for a Rails app"
    assert_includes markdown, "## Education"
  end
end
