class OptimizedResume < ApplicationRecord
  belongs_to :resume
  has_one_attached :pdf
end
