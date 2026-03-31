class RemoveDefaultResumes < ActiveRecord::Migration[8.1]
  def change
    drop_table :default_resumes
  end
end
