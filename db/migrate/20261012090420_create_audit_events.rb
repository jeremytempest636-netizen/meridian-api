class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :work_order, null: false, foreign_key: true
      t.string :actor
      t.string :action
      t.jsonb :changeset

      t.timestamps
    end
  end
end
