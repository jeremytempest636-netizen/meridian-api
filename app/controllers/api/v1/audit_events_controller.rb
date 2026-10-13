module Api
  module V1
    class AuditEventsController < ApplicationController
      include Authenticatable

      before_action :authenticate_user!
      before_action :set_work_order

      def index
        audit_events = @work_order.audit_events.order(created_at: :asc, id: :asc)

        render json: {
          data: audit_events.as_json(
            only: %i[id actor action changeset created_at]
          )
        }
      end

      private

      def set_work_order
        @work_order = WorkOrder.find(params[:work_order_id])
      end
    end
  end
end