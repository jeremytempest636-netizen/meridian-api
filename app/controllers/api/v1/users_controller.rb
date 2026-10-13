module Api
  module V1
    class UsersController < ApplicationController
      include Authenticatable

      before_action :authenticate_user!

      def me
        render json: {
          data: current_user.as_json(only: %i[id email role active created_at])
        }
      end

      def index
        return unless require_roles!("admin", "supervisor")
      return if performed?

        users = User.order(:id)
        render json: {
          data: users.as_json(only: %i[id email role active created_at])
        }
      end
    end
  end
end
