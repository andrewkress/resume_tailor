require "prawn"
require "kramdown"

class PdfGenerator
  class MarkdownRenderer
    BODY_FONT_SIZE = 11
    HEADER_FONT_SIZES = {
      1 => 18,
      2 => 15,
      3 => 13
    }.freeze
    SMART_QUOTES = {
      lsquo: "'",
      rsquo: "'",
      ldquo: '"',
      rdquo: '"'
    }.freeze
    TYPOGRAPHIC_SYMBOLS = {
      hellip: "...",
      ndash: "-",
      mdash: "--"
    }.freeze
    BLOCK_SPACING = 8
    LIST_INDENT = 18
    BULLET_MARKER = "-"
    LINK_COLOR = "0563C1"

    def initialize(pdf)
      @pdf = pdf
      @pdf.font_size(BODY_FONT_SIZE)
    end

    def render(markdown)
      document = Kramdown::Document.new(markdown.to_s)

      document.root.children.each do |element|
        render_block(element)
      end
    end

    private

    def render_block(element, list_depth: 0)
      case element.type
      when :blank
        nil
      when :header
        render_header(element)
      when :p
        render_paragraph(element)
      when :ul
        render_list(element, list_depth:, ordered: false)
      when :ol
        render_list(element, list_depth:, ordered: true)
      when :hr
        @pdf.stroke_horizontal_rule
        @pdf.move_down(BLOCK_SPACING)
      else
        element.children.each do |child|
          render_block(child, list_depth:)
        end
      end
    end

    def render_header(element)
      @pdf.font_size(header_font_size(element)) do
        @pdf.formatted_text(
          inline_fragments(element.children, inherited_styles: [ :bold ]),
          leading: 4
        )
      end
      @pdf.move_down(BLOCK_SPACING)
    end

    def render_paragraph(element)
      fragments = inline_fragments(element.children)
      return if fragments.empty?

      @pdf.formatted_text(fragments, leading: 4)
      @pdf.move_down(BLOCK_SPACING)
    end

    def render_list(element, list_depth:, ordered:)
      element.children.each_with_index do |item, index|
        marker = ordered ? "#{index + 1}." : BULLET_MARKER
        render_list_item(item, marker:, list_depth:)
      end

      @pdf.move_down(BLOCK_SPACING / 2)
    end

    def render_list_item(item, marker:, list_depth:)
      blocks = item.children.reject { |child| child.type == :blank }
      first_block = blocks.shift

      @pdf.indent(LIST_INDENT * list_depth) do
        if first_block&.type == :p
          fragments = [
            { text: "#{marker} ", styles: [ :bold ] },
            *inline_fragments(first_block.children)
          ]
          @pdf.formatted_text(fragments, leading: 4)
          @pdf.move_down(BLOCK_SPACING / 2)
        elsif first_block
          render_block(first_block, list_depth: list_depth + 1)
        end

        blocks.each do |block|
          render_block(block, list_depth: list_depth + 1)
        end
      end
    end

    def inline_fragments(children, inherited_styles: [])
      children.flat_map do |child|
        render_inline(child, inherited_styles:)
      end
    end

    def render_inline(element, inherited_styles: [])
      case element.type
      when :text
        text_fragment(element.value, inherited_styles)
      when :strong
        inline_fragments(element.children, inherited_styles: inherited_styles + [ :bold ])
      when :em
        inline_fragments(element.children, inherited_styles: inherited_styles + [ :italic ])
      when :codespan
        inline_fragments(element.children, inherited_styles: inherited_styles + [ :italic ])
      when :a
        inline_fragments(element.children, inherited_styles: inherited_styles + [ :underline ]).map do |fragment|
          fragment.merge(color: LINK_COLOR)
        end
      when :entity
        text_fragment(element.value.char, inherited_styles)
      when :smart_quote
        text_fragment(SMART_QUOTES.fetch(element.value, ""), inherited_styles)
      when :typographic_sym
        text_fragment(TYPOGRAPHIC_SYMBOLS.fetch(element.value, ""), inherited_styles)
      when :line_break
        text_fragment("\n", inherited_styles)
      else
        inline_fragments(element.children, inherited_styles:)
      end
    end

    def text_fragment(text, styles)
      return [] if text.blank?

      [ { text:, styles: styles.uniq } ]
    end

    def header_font_size(element)
      HEADER_FONT_SIZES.fetch(element.options[:level], BODY_FONT_SIZE)
    end
  end

  def initialize(optimized_text)
    @optimized_text = Windows1252Sanitizer.call(optimized_text)
  end

  def generate
    Tempfile.new([ "optimized_resume", ".pdf" ]).tap do |file|
      file.binmode
      Prawn::Document.generate(file.path, overwrite_content: true) do |pdf|
        MarkdownRenderer.new(pdf).render(@optimized_text)
      end
      file.rewind
    end
  end
end
