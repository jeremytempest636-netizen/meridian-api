class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders do |t|
      t.string :title
      t.text :description
      t.string :status
      t.string :priority
      t.datetime :due_at

      t.timestamps
    end
  end
end
