class WorkOrderAuditLogger
  def self.log(work_order:, actor:, action:, changeset: {})
    work_order.audit_events.create!(
      actor: actor,
      action: action,
      changeset: changeset
    )
  end
end
