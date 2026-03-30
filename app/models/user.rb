class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :resumes, dependent: :destroy
  has_one :default_resume, dependent: :destroy

  accepts_nested_attributes_for :default_resume, update_only: true, reject_if: :all_blank
end
