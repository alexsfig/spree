module Spree
  module Api
    module V1
      class OrdersController < Spree::Api::V1::BaseController
        def index
          # should probably look at turning this into a CanCan step
          raise CanCan::AccessDenied unless current_api_user.has_role?("admin")
          @orders = Order.page(params[:page])
        end

        def show
          authorize! :read, order
        end

        def create
          @order = Order.build_from_api(current_api_user, params[:order])
          next!
        end

        def update
          Rails.logger.debug(params.inspect)
          authorize! :update, Order
          if order.update_attributes(params[:order])
            render :show
          else
            invalid_resource!(order)
          end
        end

        def address
          order.build_ship_address(params[:shipping_address])
          order.build_bill_address(params[:billing_address])
          next!
        end

        def delivery
          begin
            ShippingMethod.find(params[:shipping_method_id])
          rescue ActiveRecord::RecordNotFound
            render :invalid_shipping_method, :status => 422
          else
            order.update_attribute(:shipping_method_id, params[:shipping_method_id])
            next!
          end
        end

        private

        def order
          @order ||= Order.find_by_number!(params[:id])
        end

        def next!
          if @order.valid? && @order.next
            render :show, :status => 200
          else
            render :could_not_transition, :status => 422
          end
        end
      end
    end
  end
end
