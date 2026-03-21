class Resume < ApplicationRecord
  belongs_to :user
  has_one_attached :original_file
  has_many :optimized_resumes, dependent: :destroy

  validates :job_description, presence: true
  validates :original_file, presence: true

  STATUSES = %w[pending processing completed failed].freeze
  validates :status, inclusion: { in: STATUSES }

  after_initialize :set_default_status

  private

  def set_default_status
    self.status ||= 'pending'
  end
end
