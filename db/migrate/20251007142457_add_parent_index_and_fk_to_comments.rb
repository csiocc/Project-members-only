class AddParentIndexAndFkToComments < ActiveRecord::Migration[7.1]
  def change
    # lege nur an, wenn nicht vorhanden
    add_index :comments, :parent_id, if_not_exists: true

    # optional – beschleunigt Queries auf Root-Kommentare je Post
    add_index :comments, [:post_id, :parent_id], if_not_exists: true

    # FK nur hinzufügen, wenn sie fehlt
    unless foreign_key_exists?(:comments, :comments, column: :parent_id)
      add_foreign_key :comments, :comments, column: :parent_id, on_delete: :cascade
    end
  end
end
