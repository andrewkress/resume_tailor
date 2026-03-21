class CreateResumes < ActiveRecord::Migration[8.1]
  def change
    create_table :resumes do |t|
      t.references :user, null: false, foreign_key: true
      t.text :job_description
      t.string :original_filename
      t.string :status

      t.timestamps
    end
  end
end
