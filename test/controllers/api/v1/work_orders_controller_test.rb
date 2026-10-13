require "test_helper"

class Api::V1::WorkOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @technician = users(:technician)

    @supervisor = User.create!(
      email: "supervisor@example.test",
      password: "TestPassword123!",
      password_confirmation: "TestPassword123!",
      role: "supervisor",
      active: true
    )

    @valid_params = {
      work_order: {
        title: "Test API Work Order",
        description: "Created through API integration test",
        status: "open",
        priority: "high",
        assignee: "DevOps Engineer"
      }
    }
  end

  test "GET index returns work orders with pagination metadata" do
    get api_v1_work_orders_url, headers: authenticate_as(@technician)

    assert_response :success
    assert_kind_of Hash, response.parsed_body
    assert_kind_of Array, response.parsed_body["data"]
    assert_kind_of Hash, response.parsed_body["meta"]
    assert_equal 1, response.parsed_body["meta"]["page"]
  end

  test "GET index rejects non-numeric pagination" do
    get api_v1_work_orders_url(page: "abc"),
        headers: authenticate_as(@technician)

    assert_response :bad_request
    assert_equal "invalid_pagination", response.parsed_body.dig("error", "code")
  end

  test "GET index rejects zero page" do
    get api_v1_work_orders_url(page: 0),
        headers: authenticate_as(@technician)

    assert_response :bad_request
  end

  test "GET index rejects non-numeric per_page" do
    get api_v1_work_orders_url(per_page: "abc"),
        headers: authenticate_as(@technician)

    assert_response :bad_request
  end

  test "GET index rejects invalid status filter" do
    get api_v1_work_orders_url(status: "banana"),
        headers: authenticate_as(@technician)

    assert_response :bad_request
  end

  test "GET index rejects invalid priority filter" do
    get api_v1_work_orders_url(priority: "urgent"),
        headers: authenticate_as(@technician)

    assert_response :bad_request
  end

  test "GET index accepts valid status and priority filters" do
    get api_v1_work_orders_url(status: "open", priority: "high"),
        headers: authenticate_as(@technician)

    assert_response :success
    assert_kind_of Array, response.parsed_body["data"]
  end

  test "GET index rejects missing token" do
    get api_v1_work_orders_url

    assert_response :unauthorized
  end

  test "GET overdue accepts an authenticated technician" do
    get "/api/v1/work_orders/overdue",
        headers: authenticate_as(@technician)

    assert_response :success
  end

  test "POST create creates a valid work order as admin" do
    assert_difference("WorkOrder.count", 1) do
      post api_v1_work_orders_url,
           params: @valid_params,
           headers: authenticate_as(@admin)
    end

    assert_response :created
    assert_equal "Test API Work Order", response.parsed_body["title"]
  end

  test "POST create rejects invalid work order" do
    assert_no_difference("WorkOrder.count") do
      post api_v1_work_orders_url,
           params: {
             work_order: {
               title: "",
               status: "banana",
               priority: "high"
             }
           },
           headers: authenticate_as(@admin)
    end

    assert_response :unprocessable_entity
    assert_equal "validation_failed", response.parsed_body.dig("error", "code")
  end

  test "POST create records an audit event with the acting user" do
    assert_difference("AuditEvent.count", 1) do
      post api_v1_work_orders_url,
           params: @valid_params,
           headers: authenticate_as(@admin)
    end

    assert_response :created

    event = AuditEvent.find_by!(
      work_order_id: response.parsed_body["id"]
    )

    assert_equal "created", event.action
    assert_equal @admin.email, event.actor
    assert_equal "open", event.changeset["status"].last
  end

  test "POST create is forbidden for technician" do
    assert_no_difference("WorkOrder.count") do
      post api_v1_work_orders_url,
           params: @valid_params,
           headers: authenticate_as(@technician)
    end

    assert_response :forbidden
  end

  test "POST create is allowed for supervisor" do
    assert_difference("WorkOrder.count", 1) do
      post api_v1_work_orders_url,
           params: @valid_params,
           headers: authenticate_as(@supervisor)
    end

    assert_response :created
  end

  test "PATCH update records status changes in an audit event" do
    work_order = WorkOrder.create!(
      title: "Audit Update Test",
      description: "Testing status change audit",
      status: "open",
      priority: "high"
    )

    assert_difference("AuditEvent.count", 1) do
      patch api_v1_work_order_url(work_order),
            params: { work_order: { status: "in_progress" } },
            headers: authenticate_as(@admin)
    end

    assert_response :success

    event = work_order.audit_events.order(:id).last

    assert_equal "updated", event.action
    assert_equal @admin.email, event.actor
    assert_equal "open", event.changeset["status"].first
    assert_equal "in_progress", event.changeset["status"].last
  end

  test "PATCH update is forbidden for technician" do
    work_order = WorkOrder.create!(
      title: "Restricted Update Test",
      status: "open",
      priority: "high"
    )

    patch api_v1_work_order_url(work_order),
          params: { work_order: { status: "in_progress" } },
          headers: authenticate_as(@technician)

    assert_response :forbidden
    assert_equal "open", work_order.reload.status
  end

  test "PATCH update is allowed for supervisor" do
    work_order = WorkOrder.create!(
      title: "Supervisor Update Test",
      status: "open",
      priority: "high"
    )

    patch api_v1_work_order_url(work_order),
          params: { work_order: { status: "in_progress" } },
          headers: authenticate_as(@supervisor)

    assert_response :success
    assert_equal "in_progress", work_order.reload.status
  end

  test "DELETE destroy is forbidden for supervisor" do
    work_order = WorkOrder.create!(
      title: "Supervisor Delete Test",
      status: "open",
      priority: "high"
    )

    assert_no_difference("WorkOrder.count") do
      delete api_v1_work_order_url(work_order),
             headers: authenticate_as(@supervisor)
    end

    assert_response :forbidden
  end

  test "DELETE destroy is forbidden for technician" do
    work_order = WorkOrder.create!(
      title: "Technician Delete Test",
      status: "open",
      priority: "high"
    )

    assert_no_difference("WorkOrder.count") do
      delete api_v1_work_order_url(work_order),
             headers: authenticate_as(@technician)
    end

    assert_response :forbidden
  end

  test "DELETE destroy is allowed for admin" do
    work_order = WorkOrder.create!(
      title: "Admin Delete Test",
      status: "open",
      priority: "high"
    )

    assert_difference("WorkOrder.count", -1) do
      delete api_v1_work_order_url(work_order),
             headers: authenticate_as(@admin)
    end

    assert_response :no_content
  end

  test "POST create rolls back work order when audit logging fails" do
    original_logger = WorkOrderAuditLogger.method(:log)

    begin
      WorkOrderAuditLogger.define_singleton_method(:log) do |**_args|
        raise ActiveRecord::RecordInvalid.new(WorkOrder.new)
      end

      assert_no_difference("WorkOrder.count") do
        assert_no_difference("AuditEvent.count") do
          post api_v1_work_orders_url,
               params: {
                 work_order: {
                   title: "Rollback Creation Test",
                   description: "Must not persist without audit event",
                   status: "open",
                   priority: "high"
                 }
               },
               headers: authenticate_as(@admin)
        end
      end

      assert_response :unprocessable_entity
    ensure
      WorkOrderAuditLogger.define_singleton_method(:log, original_logger)
    end
  end

  test "PATCH update rolls back work order when audit logging fails" do
    work_order = WorkOrder.create!(
      title: "Rollback Update Test",
      description: "Original description",
      status: "open",
      priority: "high"
    )

    original_status = work_order.status
    original_logger = WorkOrderAuditLogger.method(:log)

    begin
      WorkOrderAuditLogger.define_singleton_method(:log) do |**_args|
        raise ActiveRecord::RecordInvalid.new(work_order)
      end

      assert_no_difference("AuditEvent.count") do
        patch api_v1_work_order_url(work_order),
              params: { work_order: { status: "in_progress" } },
              headers: authenticate_as(@admin)
      end

      assert_response :unprocessable_entity
      assert_equal original_status, work_order.reload.status
    ensure
      WorkOrderAuditLogger.define_singleton_method(:log, original_logger)
    end
  end
  test "GET show returns 404 JSON when work order does not exist" do
    get api_v1_work_order_url(id: 99999999),
        headers: authenticate_as(@technician)

    assert_response :not_found

    error = response.parsed_body.fetch("error")
    assert_equal "not_found", error["code"]
    assert_equal "Resource not found", error["message"]
    assert error["request_id"].present?
  end
  test "GET index only returns work orders assigned to the technician" do
    assigned = WorkOrder.create!(
      title: "Assigned Work Order",
      status: "open",
      priority: "high",
      assigned_user: @technician
    )

    WorkOrder.create!(
      title: "Unassigned Work Order",
      status: "open",
      priority: "high"
    )

    get api_v1_work_orders_url,
        headers: authenticate_as(@technician)

    assert_response :success
    ids = response.parsed_body["data"].map { |item| item["id"] }
    assert_includes ids, assigned.id
    assert_equal 1, ids.length
  end

  test "GET show hides work orders assigned to another technician" do
    other_technician = User.create!(
      email: "other-technician@example.test",
      password: "TestPassword123!",
      role: "technician",
      active: true
    )

    work_order = WorkOrder.create!(
      title: "Private Work Order",
      status: "open",
      priority: "high",
      assigned_user: other_technician
    )

    get api_v1_work_order_url(work_order),
        headers: authenticate_as(@technician)

    assert_response :not_found
    assert_equal "not_found", response.parsed_body.dig("error", "code")
  end
end
