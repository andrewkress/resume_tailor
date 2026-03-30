class DefaultResume < ApplicationRecord
  belongs_to :user
  has_one_attached :default_pdf

  validates :user_id, uniqueness: true
  validates :markdown, presence: true, unless: :content_provided?

  before_validation :populate_markdown_from_pdf

  private

  def content_provided?
    default_pdf.attached? || markdown.present?
  end

  def populate_markdown_from_pdf
    return unless default_pdf.attached?
    return if markdown.present?

    self.markdown = ResumeTextExtractor.new(default_pdf).extract
  rescue => e
    Rails.logger.error("Error extracting markdown from default resume file: #{e.message}")
  end
end
