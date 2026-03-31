require "test_helper"

class PdfGeneratorTest < ActiveSupport::TestCase
  test "sanitizes markdown before rendering the pdf" do
    rendered_text = nil

    markdown_renderer = Object.new
    markdown_renderer.define_singleton_method(:font_size) { |_size| }
    markdown_renderer.define_singleton_method(:markdown) do |text, **|
      rendered_text = text
    end

    prawn_stub = lambda do |_path, overwrite_content:, &block|
      block.call(markdown_renderer)
    end

    Prawn::Document.stub(:generate, prawn_stub) do
      PdfGenerator.new("Built features\u2009with care \u2713").generate
    end

    assert_equal "Built features with care *", rendered_text
  end
end
