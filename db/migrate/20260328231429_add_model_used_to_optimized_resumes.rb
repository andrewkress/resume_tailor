class AddModelUsedToOptimizedResumes < ActiveRecord::Migration[8.1]
  def change
    add_column :optimized_resumes, :model_used, :string
  end
end
