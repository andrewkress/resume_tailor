class Resume < ApplicationRecord
  belongs_to :user
  has_one_attached :original_file
  has_one_attached :optimization_source_file
  has_many :optimized_resumes, dependent: :destroy

  validates :job_description, presence: true
  validates :company_name, length: { maximum: 255 }
  validates :application_link, length: { maximum: 2048 }
  validate :must_have_default_or_uploaded_file

  STATUSES = %w[pending processing completed failed].freeze
  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status
  after_update_commit :broadcast_status_update

  def snapshot_optimization_source!
    source_attachment = preferred_optimization_source_attachment
    source_kind = source_attachment == user.default_pdf ? "default_pdf" : "uploaded_file"

    optimization_source_file.attach(
      io: StringIO.new(source_attachment.download),
      filename: source_attachment.filename.to_s,
      content_type: source_attachment.content_type,
      metadata: { source_kind: source_kind }
    )

    update_column(:optimization_source_kind, source_kind)
  end

  def optimization_source_attachment
    optimization_source_file.attached? ? optimization_source_file : original_file
  end

  def optimization_source_kind
    self[:optimization_source_kind].presence ||
      optimization_source_file.blob&.metadata&.[]("source_kind").presence ||
      "uploaded_file"
  end

  def optimization_source_label
    optimization_source_kind == "default_pdf" ? "Profile default resume" : "Uploaded resume"
  end

  def optimization_source_summary
    if optimization_source_kind == "default_pdf"
      "A snapshot of your profile default resume was captured when this resume was created and will stay fixed for all regenerations."
    else
      "No profile default resume was available, so the uploaded resume for this entry is the source for all regenerations."
    end
  end

  private

  def preferred_optimization_source_attachment
    user.default_pdf.attached? ? user.default_pdf : original_file
  end

  def must_have_default_or_uploaded_file
    return if original_file.attached? || user&.default_pdf&.attached?

    errors.add(:original_file, "must be uploaded unless you have a default resume on your profile")
  end

  def broadcast_status_update
    broadcast_replace_later_to(
      self,
      target: "resume_#{id}_status",
      partial: "resumes/status",
      locals: { resume: self }
    )
  end

  def set_default_status
    self.status ||= "pending"
  end
end
