class ResumeMarkdownFormatter
  SECTION_HEADINGS = %w[
    summary
    profile
    experience
    work experience
    professional experience
    education
    skills
    projects
    certifications
    awards
    publications
    volunteer
    leadership
    technical skills
  ].freeze

  def initialize(text)
    @text = text.to_s
  end

  def format
    return "" if normalized_lines.empty?

    markdown_lines = []
    title_assigned = false

    normalized_lines.each_with_index do |line, index|
      markdown_lines << "" if index.positive? && paragraph_break?(line, markdown_lines.last)
      markdown_lines << format_line(line, title_assigned)
      title_assigned = true if markdown_title?(line, title_assigned)
    end

    markdown_lines
      .flatten
      .compact
      .map(&:rstrip)
      .join("\n")
      .gsub(/\n{3,}/, "\n\n")
      .strip
  end

  private

  def normalized_lines
    @normalized_lines ||= @text
      .gsub("\r\n", "\n")
      .lines
      .map { |line| normalize_line(line) }
      .reject(&:empty?)
  end

  def normalize_line(line)
    line.to_s
      .tr("\u00A0", " ")
      .gsub(/[[:space:]]+/, " ")
      .strip
  end

  def format_line(line, title_assigned)
    return "# #{line}" if markdown_title?(line, title_assigned)
    return "## #{normalized_heading(line)}" if heading?(line)
    return "- #{normalize_bullet(line)}" if bullet?(line)

    line
  end

  def markdown_title?(line, title_assigned)
    !title_assigned && !heading?(line) && !bullet?(line)
  end

  def heading?(line)
    return true if SECTION_HEADINGS.include?(line.downcase.delete(":"))
    return false if bullet?(line)
    return false if line.length > 60

    letters = line.gsub(/[^A-Za-z]/, "")
    return false if letters.empty?

    uppercase_heading?(line) || colon_heading?(line)
  end

  def uppercase_heading?(line)
    letters = line.gsub(/[^A-Za-z]/, "")
    letters == letters.upcase && letters.length > 2
  end

  def colon_heading?(line)
    line.end_with?(":") && line.count(" ") <= 4
  end

  def normalized_heading(line)
    line.delete_suffix(":").split.map(&:capitalize).join(" ")
  end

  def bullet?(line)
    line.match?(/\A(?:[-*•·]|(?:\d+[\.\)]))\s+/)
  end

  def normalize_bullet(line)
    line.sub(/\A(?:[-*•·]|(?:\d+[\.\)]))\s+/, "").strip
  end

  def paragraph_break?(line, previous_line)
    return false if previous_line.blank?
    return false if previous_line.start_with?("#")
    return false if previous_line.start_with?("- ")
    return false if heading?(line)
    return false if bullet?(line)

    line.length < 40
  end
end
