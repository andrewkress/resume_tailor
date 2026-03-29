require "test_helper"

class ResumeTextExtractorTest < ActiveSupport::TestCase
  test "extract delegates pdf files to pdf extractor" do
    file = mock_file("resume.pdf")
    extractor = ResumeTextExtractor.new(file)

    extractor.stub(:extract_from_pdf, "pdf text") do
      assert_equal "pdf text", extractor.extract
    end
  end

  test "extract delegates docx files to docx extractor" do
    file = mock_file("resume.docx")
    extractor = ResumeTextExtractor.new(file)

    extractor.stub(:extract_from_docx, "docx text") do
      assert_equal "docx text", extractor.extract
    end
  end

  test "extract supports uploaded files that expose original_filename" do
    file = Struct.new(:original_filename).new("resume.pdf")
    extractor = ResumeTextExtractor.new(file)

    extractor.stub(:extract_from_pdf, "pdf text") do
      assert_equal "pdf text", extractor.extract
    end
  end

  test "extract raises a helpful error for unsupported file types" do
    file = mock_file("resume.txt")
    error = assert_raises(ResumeTextExtractor::UnsupportedFileTypeError) do
      ResumeTextExtractor.new(file).extract
    end

    assert_match("resume.txt", error.message)
  end

  private

  def mock_file(name)
    Struct.new(:filename).new(name)
  end
end
