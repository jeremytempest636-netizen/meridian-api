class AddAssignmentAndSlaToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :assignee, :string
    add_column :work_orders, :sla_due_at, :datetime
    add_column :work_orders, :resolved_at, :datetime
  end
end
