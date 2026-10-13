class HardenUsersTable < ActiveRecord::Migration[8.1]
  def change
    change_column_default :users, :role, from: nil, to: "technician"
    change_column_default :users, :active, from: nil, to: true
    change_column_null :users, :email, false
    change_column_null :users, :password_digest, false
    change_column_null :users, :role, false
    change_column_null :users, :active, false

    add_index :users, "LOWER(email)", unique: true,
              name: "index_users_on_lower_email"
  end
end
