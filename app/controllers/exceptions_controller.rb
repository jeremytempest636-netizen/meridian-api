class ExceptionsController < ActionController::API
  def show
    exception = request.env["action_dispatch.exception"]
    status = ActionDispatch::ExceptionWrapper.status_code_for_exception(
      exception.class.name
    )

    code, message =
      if status == 404
        [ "not_found", "Resource not found" ]
      else
        [ "internal_server_error", "An unexpected error occurred" ]
      end

    render json: {
      error: {
        code: code,
        message: message,
        request_id: request.request_id
      }
    }, status: status
  end
end
