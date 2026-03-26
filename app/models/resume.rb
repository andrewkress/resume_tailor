class Resume < ApplicationRecord
  belongs_to :user
  has_one_attached :original_file
  has_many :optimized_resumes, dependent: :destroy

  validates :job_description, presence: true
  validates :original_file, presence: true
  validates :company_name, length: { maximum: 255 }
  validates :application_link, length: { maximum: 2048 }

  STATUSES = %w[pending processing completed failed].freeze
  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status
  after_update_commit :broadcast_status_update

  private

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
