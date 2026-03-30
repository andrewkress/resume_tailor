class OptimizedResume < ApplicationRecord
  MODELS = %w[sonnet_4_6 haiku_4_5 gpt_oss_120 gpt_oss_20 manual_edit].freeze

  belongs_to :resume
  has_one_attached :pdf
  validates :markdown, presence: true
  validates :model_used, inclusion: { in: MODELS }, allow_nil: true
end
