class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_api_error(code:, message:, status:, details: nil)
    error = {
      code: code,
      message: message,
      request_id: request.request_id
    }
    error[:details] = details if details.present?

    render json: { error: error }, status: status
  end

  def render_not_found
    render_api_error(
      code: "not_found",
      message: "Resource not found",
      status: :not_found
    )
  end
end
