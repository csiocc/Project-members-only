
class AddingEncryptedPw < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :encrypted_password, :string, null: false, default: "" unless column_exists?(:users, :encrypted_password)

    # Nur kopieren, wenn es die alte Spalte gibt
    if column_exists?(:users, :password_digest)
      say_with_time "Copy password_digest -> encrypted_password" do
        execute <<~SQL.squish
          UPDATE users
          SET encrypted_password = password_digest
          WHERE COALESCE(password_digest, '') <> '';
        SQL
      end


      remove_column :users, :password_digest
    else
      say "password_digest not found; skipping copy"
    end
  end

  def down
    # Rückwärts: optional wiederherstellen
    add_column :users, :password_digest, :string unless column_exists?(:users, :password_digest)

    if column_exists?(:users, :encrypted_password)
      execute <<~SQL.squish
        UPDATE users
        SET password_digest = encrypted_password
        WHERE COALESCE(encrypted_password, '') <> '';
      SQL
    end

    remove_column :users, :encrypted_password if column_exists?(:users, :encrypted_password)
  end
end
