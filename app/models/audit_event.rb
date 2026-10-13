class AuditEvent < ApplicationRecord
  belongs_to :work_order

  validates :actor, presence: true, length: { maximum: 100 }
  validates :action, presence: true, length: { maximum: 50 }
  validates :changeset, presence: true
end
