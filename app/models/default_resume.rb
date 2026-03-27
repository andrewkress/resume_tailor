class DefaultResume < ApplicationRecord
  belongs_to :user
  has_one_attached :default_pdf

  validates :markdown, presence: true
end
