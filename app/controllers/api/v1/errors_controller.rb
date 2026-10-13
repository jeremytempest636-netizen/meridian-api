module Api
  module V1
    class ErrorsController < ApplicationController
      def not_found
        render_api_error(
          code: "not_found",
          message: "Resource not found",
          status: :not_found
        )
      end
    end
  end
end
