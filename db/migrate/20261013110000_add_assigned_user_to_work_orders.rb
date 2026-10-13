class AddAssignedUserToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :work_orders,
                  :assigned_user,
                  foreign_key: { to_table: :users },
                  null: true,
                  index: true
  end
end
