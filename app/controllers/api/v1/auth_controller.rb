module Api
  module V1
    class AuthController < ApplicationController
      def register
        user = User.new(registration_params)
        user.role = "technician"
        user.active = true

        if user.save
          render json: {
            data: user.as_json(only: %i[id email role created_at])
          }, status: :created
        else
          render_api_error(code: "validation_failed", message: "Registration failed", status: :unprocessable_entity, details: user.errors.full_messages)
        end
      end

      def login
        user = User.active.find_by(email: params[:email].to_s.strip.downcase)

        if user&.authenticate(params[:password].to_s)
          render json: {
            access_token: JsonWebToken.encode(user),
            token_type: "Bearer",
            expires_in: JsonWebToken::TOKEN_TTL.to_i,
            user: user.as_json(only: %i[id email role])
          }
        else
          render_api_error(code: "unauthorized", message: "Invalid email or password", status: :unauthorized)
        end
      end

      private

      def registration_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
