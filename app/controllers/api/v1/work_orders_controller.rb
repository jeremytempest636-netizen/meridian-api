module Api
  module V1
    class WorkOrdersController < ApplicationController
      include Authenticatable

      before_action :authenticate_user!
      before_action :authorize_work_order_action!
      before_action :set_work_order, only: %i[show update destroy]

      def index
        work_orders = WorkOrder.order(created_at: :desc)

        if params[:status].present? && !WorkOrder::STATUSES.include?(params[:status].to_s)
          return render_api_error(code: "invalid_status_filter", message: "The status filter is invalid", status: :bad_request)
        end

        if params[:priority].present? && !WorkOrder::PRIORITIES.include?(params[:priority].to_s)
          return render_api_error(code: "invalid_priority_filter", message: "The priority filter is invalid", status: :bad_request)
        end

        work_orders = work_orders.where(status: params[:status]) if params[:status].present?
        work_orders = work_orders.where(priority: params[:priority]) if params[:priority].present?
        work_orders = work_orders.where(assignee: params[:assignee]) if params[:assignee].present?

        if params[:search].present?
          term = "%#{ActiveRecord::Base.sanitize_sql_like(params[:search].to_s.strip)}%"
          work_orders = work_orders.where(
            "title ILIKE :term OR description ILIKE :term",
            term: term
          )
        end

        total_count = work_orders.count

        page_input = params[:page].presence || "1"
        per_page_input = params[:per_page].presence || "10"

        unless page_input.to_s.match?(/\A[1-9]\d*\z/) &&
               per_page_input.to_s.match?(/\A[1-9]\d*\z/)
          return render_api_error(
            code: "invalid_pagination",
            message: "page and per_page must be positive integers",
            status: :bad_request
          )
        end

        page = page_input.to_i
        per_page = per_page_input.to_i.clamp(1, 100)
        total_pages = (total_count.to_f / per_page).ceil

        work_orders = work_orders
          .limit(per_page)
          .offset((page - 1) * per_page)

        render json: {
          data: work_orders,
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: total_pages
          }
        }
      end

      def overdue
        work_orders = WorkOrder.overdue.order(sla_due_at: :asc)
        render json: work_orders
      end

      def show
        render json: @work_order
      end

      def create
        work_order = WorkOrder.new(work_order_params)

        WorkOrder.transaction do
          work_order.save!

          WorkOrderAuditLogger.log(
            work_order: work_order,
            actor: current_user.email,
            action: "created",
            changeset: work_order.saved_changes.except("created_at", "updated_at")
          )
        end

        render json: work_order, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_api_error(code: "validation_failed", message: "Work order validation failed", status: :unprocessable_entity, details: e.record.errors.full_messages)
      end

      def update
        WorkOrder.transaction do
          @work_order.update!(work_order_params)

          WorkOrderAuditLogger.log(
            work_order: @work_order,
            actor: current_user.email,
            action: "updated",
            changeset: @work_order.saved_changes.except("updated_at")
          )
        end

        render json: @work_order
      rescue ActiveRecord::RecordInvalid => e
        render_api_error(code: "validation_failed", message: "Work order validation failed", status: :unprocessable_entity, details: e.record.errors.full_messages)
      end

      def destroy
        @work_order.destroy!
        head :no_content
      end

      private

      def authorize_work_order_action!
        case action_name
        when "create", "update"
          require_roles!("admin", "supervisor")
        when "destroy"
          require_roles!("admin")
        end
      end

      def set_work_order
        @work_order = WorkOrder.find(params[:id])
      end

      def work_order_params
        params.require(:work_order).permit(
          :title,
          :description,
          :status,
          :priority,
          :due_at,
          :assignee,
          :sla_due_at
        )
      end
    end
  end
end
