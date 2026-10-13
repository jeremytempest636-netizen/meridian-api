
class WorkOrder < ApplicationRecord
  has_many :audit_events, dependent: :destroy
  STATUSES = %w[open in_progress resolved closed].freeze
  PRIORITIES = %w[low medium high critical].freeze

  scope :overdue, -> {
    where.not(status: %w[resolved closed])
      .where.not(sla_due_at: nil)
      .where("sla_due_at < ?", Time.current)
  }

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 5000 }, allow_blank: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates :assignee, length: { maximum: 100 }, allow_blank: true

  validate :due_at_must_be_in_the_future, if: -> { due_at.present? }

  validate :sla_due_at_must_be_in_the_future,
           if: -> { sla_due_at.present? && new_record? }

  before_validation :set_resolved_at, if: :resolution_status?

  private

  def due_at_must_be_in_the_future
    if due_at <= Time.current
      errors.add(:due_at, "must be in the future")
    end
  end

  def sla_due_at_must_be_in_the_future
    if sla_due_at <= Time.current
      errors.add(:sla_due_at, "must be in the future")
    end
  end

  def resolution_status?
    status == "resolved" && will_save_change_to_status?
  end

  def set_resolved_at
    self.resolved_at ||= Time.current
  end
end
