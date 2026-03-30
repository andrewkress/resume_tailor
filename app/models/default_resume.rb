class DefaultResume < ApplicationRecord
  belongs_to :user
  has_one_attached :default_pdf

  validates :user_id, uniqueness: true
  validates :markdown, presence: true, unless: :content_provided?

  after_commit :populate_markdown_from_pdf, on: [ :create, :update ], if: :should_populate_markdown_from_pdf?

  private

  def content_provided?
    default_pdf.attached? || markdown.present?
  end

  def should_populate_markdown_from_pdf?
    default_pdf.attached? && markdown.blank?
  end

  def populate_markdown_from_pdf
    extracted_markdown = ResumeTextExtractor.new(default_pdf).extract
    update_columns(markdown: extracted_markdown, updated_at: Time.current)
  rescue => e
    Rails.logger.error("Error extracting markdown from default resume file: #{e.message}")
  end
end
