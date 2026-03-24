class OptimizedResume < ApplicationRecord
  belongs_to :resume
  has_one_attached :pdf
  validates :markdown, presence: true
end
