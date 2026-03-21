class CreateOptimizedResumes < ActiveRecord::Migration[8.1]
  def change
    create_table :optimized_resumes do |t|
      t.references :resume, null: false, foreign_key: true
      t.string :s3_url
      t.string :s3_key

      t.timestamps
    end
  end
end
