class AddDefaultResumes < ActiveRecord::Migration[8.1]
  def change
    create_table :default_resumes do |t|
      t.references :user, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.text :markdown

      t.timestamps
    end
  end
end
