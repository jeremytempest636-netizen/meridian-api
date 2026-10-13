module Authenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  private

  def authenticate_user!
    header = request.headers["Authorization"].to_s
    token = header[/\ABearer\s+(.+)\z/i, 1]
    payload = JsonWebToken.decode(token) if token.present?

    @current_user = User.active.find_by(id: payload&.fetch("sub", nil))

    return if @current_user

    render_api_error(code: "unauthorized", message: "Authentication required", status: :unauthorized)
  end

  def require_roles!(*roles)
    return if performed?
    return if current_user && roles.include?(current_user.role)

    render_api_error(code: "forbidden", message: "You are not allowed to perform this action", status: :forbidden)
  end
end
