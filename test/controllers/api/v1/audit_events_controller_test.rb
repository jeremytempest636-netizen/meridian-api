require "test_helper"

class Api::V1::AuditEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @work_order = WorkOrder.create!(
      title: "Audit Trail Test",
      description: "Testing audit events endpoint",
      status: "open",
      priority: "high"
    )

    @work_order.audit_events.create!(
      actor: "system",
      action: "created",
      changeset: { "status" => [nil, "open"] }
    )

    @work_order.audit_events.create!(
      actor: "system",
      action: "updated",
      changeset: { "status" => ["open", "in_progress"] }
    )
  end

  test "returns audit events in chronological order for an authenticated technician" do
    get "/api/v1/work_orders/#{@work_order.id}/audit_events",
        headers: authenticate_as(users(:technician))

    assert_response :success

    body = response.parsed_body
    assert_equal 2, body["data"].length
    assert_equal ["created", "updated"],
                 body["data"].map { |event| event["action"] }

    assert_equal ["open", "in_progress"],
                 body["data"].last["changeset"]["status"]
  end

  test "rejects audit events request without a token" do
    get "/api/v1/work_orders/#{@work_order.id}/audit_events"

    assert_response :unauthorized
  end

  test "returns not found for a nonexistent work order when authenticated" do
    get "/api/v1/work_orders/999999/audit_events",
        headers: authenticate_as(users(:technician))

    assert_response :not_found
  end
end