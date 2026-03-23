class AddMarkdownToOptimizedResumes < ActiveRecord::Migration[8.1]
  def change
    add_column :optimized_resumes, :markdown, :text
  end
end
