class AddCompanyNameAndApplicationLinkToResumes < ActiveRecord::Migration[8.1]
  def change
    add_column :resumes, :company_name, :string
    add_column :resumes, :application_link, :string
  end
end
