require "test_helper"

class Api::V1::AuthControllerTest < ActionDispatch::IntegrationTest
  test "registers a new user as technician" do
    assert_difference("User.count", 1) do
      post "/api/v1/auth/register",
           params: {
             user: {
               email: "new.user@example.test",
               password: "TestPassword123!",
               password_confirmation: "TestPassword123!"
             }
           },
           as: :json
    end

    assert_response :created
    body = response.parsed_body

    assert_equal "new.user@example.test", body.dig("data", "email")
    assert_equal "technician", body.dig("data", "role")
    assert_not body.dig("data").key?("password_digest")
  end

  test "rejects registration with invalid email" do
    assert_no_difference("User.count") do
      post "/api/v1/auth/register",
           params: {
             user: {
               email: "invalid-email",
               password: "TestPassword123!",
               password_confirmation: "TestPassword123!"
             }
           },
           as: :json
    end

    assert_response :unprocessable_entity
  end

  test "logs in with valid credentials and returns a JWT" do
    post "/api/v1/auth/login",
         params: {
           email: "technician@example.test",
           password: "TestPassword123!"
         },
         as: :json

    assert_response :success

    body = response.parsed_body
    assert_equal "Bearer", body["token_type"]
    assert body["access_token"].present?
    assert_equal "technician", body.dig("user", "role")

    payload = JsonWebToken.decode(body["access_token"])
    assert_equal users(:technician).id.to_s, payload["sub"]
  end

  test "rejects login with incorrect password" do
    post "/api/v1/auth/login",
         params: {
           email: "technician@example.test",
           password: "WrongPassword123!"
         },
         as: :json

    assert_response :unauthorized
    assert_equal "Invalid email or password",
                 response.parsed_body.dig("error", "message")
  end

  test "rejects login for inactive user" do
    user = users(:technician)
    user.update!(active: false)

    post "/api/v1/auth/login",
         params: {
           email: user.email,
           password: "TestPassword123!"
         },
         as: :json

    assert_response :unauthorized
  end
end
