class AddActiveStorageToOptimizedResumes < ActiveRecord::Migration[8.1]
  def change
    remove_column :optimized_resumes, :s3_url, :string
    remove_column :optimized_resumes, :s3_key, :string
  end
end
