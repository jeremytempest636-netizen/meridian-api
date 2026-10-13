
require "test_helper"

class WorkOrderTest < ActiveSupport::TestCase
  def setup
    @work_order = WorkOrder.new(
      title: "Test Work Order",
      description: "Testing MERIDIAN work order",
      status: "open",
      priority: "high"
    )
  end

  test "valid work order can be saved" do
    assert @work_order.valid?
  end

  test "title is required" do
    @work_order.title = nil

    assert_not @work_order.valid?
    assert_includes @work_order.errors[:title], "can't be blank"
  end

  test "invalid status is rejected" do
    @work_order.status = "banana"

    assert_not @work_order.valid?
    assert_includes @work_order.errors[:status], "is not included in the list"
  end

  test "overdue scope finds work orders past SLA" do
    @work_order.sla_due_at = 1.hour.ago
    @work_order.save!(validate: false)

    assert_includes WorkOrder.overdue, @work_order
  end

  test "resolved work orders are excluded from overdue scope" do
    @work_order.status = "resolved"
    @work_order.sla_due_at = 1.hour.ago
    @work_order.save!(validate: false)

    assert_not_includes WorkOrder.overdue, @work_order
  end
end