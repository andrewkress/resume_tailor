require "test_helper"

class PdfGeneratorTest < ActiveSupport::TestCase
  class FakePdfDocument
    attr_reader :font_sizes, :formatted_text_calls, :move_down_calls, :horizontal_rules

    def initialize
      @font_sizes = []
      @formatted_text_calls = []
      @move_down_calls = []
      @horizontal_rules = 0
    end

    def font_size(size = nil)
      if block_given?
        @font_sizes << size
        yield
      elsif size
        @font_sizes << size
      end
    end

    def formatted_text(fragments, **options)
      @formatted_text_calls << [ fragments, options ]
    end

    def move_down(amount)
      @move_down_calls << amount
    end

    def stroke_horizontal_rule
      @horizontal_rules += 1
    end

    def indent(_amount)
      yield
    end
  end

  test "sanitizes markdown before rendering the pdf" do
    rendered_text = nil
    fake_pdf = FakePdfDocument.new

    prawn_stub = lambda do |_path, overwrite_content:, &block|
      block.call(fake_pdf)
      rendered_text = fake_pdf.formatted_text_calls.first.first.first[:text]
    end

    Prawn::Document.stub(:generate, prawn_stub) do
      PdfGenerator.new("Built features\u2009with care \u2713").generate
    end

    assert_equal "Built features with care *", rendered_text
  end

  test "renders bullet lists and horizontal rules via kramdown" do
    fake_pdf = FakePdfDocument.new

    prawn_stub = lambda do |_path, overwrite_content:, &block|
      block.call(fake_pdf)
    end

    markdown = <<~MARKDOWN
      ## Experience

      ---

      - Built internal tools
      - Improved resume matching
    MARKDOWN

    Prawn::Document.stub(:generate, prawn_stub) do
      PdfGenerator.new(markdown).generate
    end

    header_fragments = fake_pdf.formatted_text_calls.first.first
    first_list_fragments = fake_pdf.formatted_text_calls[1].first
    second_list_fragments = fake_pdf.formatted_text_calls[2].first

    assert_equal "Experience", header_fragments.first[:text]
    assert_equal 1, fake_pdf.horizontal_rules
    assert_equal "- ", first_list_fragments.first[:text]
    assert_equal "Built internal tools", first_list_fragments.second[:text]
    assert_equal "- ", second_list_fragments.first[:text]
    assert_equal "Improved resume matching", second_list_fragments.second[:text]
  end

  test "converts smart quotes and typographic symbols into strings" do
    fake_pdf = FakePdfDocument.new

    prawn_stub = lambda do |_path, overwrite_content:, &block|
      block.call(fake_pdf)
    end

    markdown = %("quoted" and 'single' and -- and ...)

    Prawn::Document.stub(:generate, prawn_stub) do
      PdfGenerator.new(markdown).generate
    end

    rendered_text = fake_pdf.formatted_text_calls.first.first.map { |fragment| fragment[:text] }.join

    assert_equal "\"quoted\" and 'single' and - and ...", rendered_text
  end
end
