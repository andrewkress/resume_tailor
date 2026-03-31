class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :resumes, dependent: :destroy
  has_one_attached :default_pdf

  accepts_nested_attributes_for :resumes, allow_destroy: true
end
