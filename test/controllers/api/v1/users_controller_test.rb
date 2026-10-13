require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  test "rejects request without token" do
    get "/api/v1/users/me"
    assert_response :unauthorized
  end

  test "rejects malformed token" do
    get "/api/v1/users/me",
        headers: { "Authorization" => "Bearer invalid.token.value" }

    assert_response :unauthorized
  end

  test "rejects token signed with the wrong secret" do
    user = users(:technician)

    token = JWT.encode(
      {
        sub: user.id.to_s,
        role: user.role,
        iat: Time.current.to_i,
        exp: 30.minutes.from_now.to_i
      },
      "incorrect-test-secret",
      JsonWebToken::ALGORITHM
    )

    get "/api/v1/users/me",
        headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unauthorized
  end

  test "rejects authorization header without Bearer scheme" do
    token = JsonWebToken.encode(users(:technician))

    get "/api/v1/users/me",
        headers: { "Authorization" => token }

    assert_response :unauthorized
  end

  test "rejects expired token" do
    user = users(:technician)

    token = JWT.encode(
      {
        sub: user.id.to_s,
        role: user.role,
        iat: 2.hours.ago.to_i,
        exp: 1.hour.ago.to_i
      },
      JsonWebToken.secret,
      JsonWebToken::ALGORITHM
    )

    get "/api/v1/users/me",
        headers: { "Authorization" => "Bearer #{token}" }

    assert_response :unauthorized
  end

  test "rejects inactive user with valid token" do
    user = users(:technician)
    headers = authenticate_as(user)
    user.update!(active: false)

    get "/api/v1/users/me", headers: headers

    assert_response :unauthorized
  end

  test "technician cannot list users" do
    get "/api/v1/users",
        headers: authenticate_as(users(:technician))

    assert_response :forbidden
  end

  test "admin can list users" do
    get "/api/v1/users",
        headers: authenticate_as(users(:admin))

    assert_response :success
  end

  test "supervisor can list users" do
    supervisor = User.create!(
      email: "supervisor-security-test@example.test",
      password: "TestPassword123!",
      role: "supervisor",
      active: true
    )

    get "/api/v1/users",
        headers: authenticate_as(supervisor)

    assert_response :success
  end

  test "technician can view own profile" do
    user = users(:technician)

    get "/api/v1/users/me",
        headers: authenticate_as(user)

    assert_response :success
  end
end
