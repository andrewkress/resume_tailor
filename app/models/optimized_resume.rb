class OptimizedResume < ApplicationRecord
  belongs_to :resume

  validates :s3_url, presence: true
  validates :s3_key, presence: true
end
