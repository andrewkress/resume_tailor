class AddOptimizationSourceKindToResumes < ActiveRecord::Migration[8.1]
  def change
    add_column :resumes, :optimization_source_kind, :string
  end
end
