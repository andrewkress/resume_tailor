class Windows1252Sanitizer
  REPLACEMENTS = {
    "\u00A0" => " ",
    "\u00AD" => "-",
    "\u2007" => " ",
    "\u2009" => " ",
    "\u200B" => "",
    "\u200C" => "",
    "\u200D" => "",
    "\u2028" => "\n",
    "\u2029" => "\n\n",
    "\u202F" => " ",
    "\u2060" => "",
    "\u2212" => "-",
    "\u2713" => "*",
    "\u2714" => "*",
    "\u2717" => "x",
    "\u2718" => "x",
    "\uFEFF" => ""
  }.freeze

  def self.call(text)
    new(text).call
  end

  def initialize(text)
    @text = text.to_s
  end

  def call
    @text.each_char.map { |char| sanitize_char(char) }.join
  end

  private

  def sanitize_char(char)
    REPLACEMENTS.fetch(char) do
      windows_1252_compatible?(char) ? char : ""
    end
  end

  def windows_1252_compatible?(char)
    char.encode(Encoding::Windows_1252)
    true
  rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
    false
  end
end
