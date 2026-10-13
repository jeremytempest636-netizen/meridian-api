require "test_helper"

class UnmatchedRoutesTest < ActionDispatch::IntegrationTest
  test "unknown API route returns standardized JSON 404" do
    get "/api/v1/route-that-does-not-exist"

    assert_response :not_found
    assert_equal "application/json", response.media_type

    error = response.parsed_body.fetch("error")
    assert_equal "not_found", error.fetch("code")
    assert_equal "Resource not found", error.fetch("message")
    assert error.fetch("request_id").present?
  end
end
