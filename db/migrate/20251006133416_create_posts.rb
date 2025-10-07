class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.text :body
      t.string :author
      t.integer :user_id
      t.integer :comment_id
      t.timestamps
    end
  end
end
