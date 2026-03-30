class OptimizedResume < ApplicationRecord
  MODELS = BedrockOptimizer::MODELS.keys.map(&:to_s).push("manual_edit").freeze
  belongs_to :resume
  has_one_attached :pdf
  validates :markdown, presence: true
  validates :model_used, inclusion: { in: MODELS }, allow_nil: true
end
