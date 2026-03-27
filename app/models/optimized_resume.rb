class OptimizedResume < ApplicationRecord
  belongs_to :resume
  has_one_attached :pdf
  belongs_to :default_resume, optional: true
  validates :markdown, presence: true
end
