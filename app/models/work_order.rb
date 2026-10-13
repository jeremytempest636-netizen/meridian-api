class WorkOrder < ApplicationRecord
  # Associations
  belongs_to :assigned_user, class_name: "User", optional: true

  has_many :audit_events, dependent: :destroy

  # Constants
  STATUSES = %w[open in_progress resolved closed].freeze
  PRIORITIES = %w[low medium high critical].freeze

  # Validations
  validates :title, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :assignee, length: { maximum: 100 }, allow_blank: true

  validate :assigned_user_must_be_active_technician
  validate :due_at_must_be_in_the_future, if: -> { due_at.present? }
  validate :sla_due_at_must_be_in_the_future,
           if: -> { sla_due_at.present? && new_record? }

  # Callbacks
  before_validation :manage_resolved_at, if: :will_save_change_to_status?

  # Scopes
  scope :overdue, lambda {
    where.not(status: %w[resolved closed])
      .where.not(sla_due_at: nil)
      .where("sla_due_at < ?", Time.current)
  }

  private

  def assigned_user_must_be_active_technician
    return if assigned_user_id.blank? && assigned_user.nil?

    unless assigned_user&.active? && assigned_user.role == "technician"
      errors.add(:assigned_user, "must be an active technician")
    end
  end

  def due_at_must_be_in_the_future
    return if due_at > Time.current

    errors.add(:due_at, "must be in the future")
  end

  def sla_due_at_must_be_in_the_future
    return if sla_due_at > Time.current

    errors.add(:sla_due_at, "must be in the future")
  end

  def manage_resolved_at
    if status == "resolved"
      self.resolved_at ||= Time.current
    elsif status_in_database == "resolved"
      self.resolved_at = nil
    end
  end
end
