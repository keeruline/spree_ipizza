module Spree
    class Gateway::IpizzaController < Spree::BaseController
      #skip_before_filter :verify_authenticity_token, :only => [:result, :success, :fail]
      #before_filter :valid_payment,                  :only => [:result]

      def show
        @order =  Order.find(params[:order_id])
        @gateway = @order.available_payment_methods.find{|x| x.id == params[:gateway_id].to_i }
        @order.payments.destroy_all
        payment = @order.payments.create!(:amount => 0,  :payment_method_id => @gateway.id)
        @order_string = ""
        @order.line_items.each do |item|
          @order_string << item.variant.product.name + ', '
        end
        @bankpayment = ::Ipizza::Payment.new(
          :stamp => @order.id.to_s, :amount => @order.total, :refnum => @order.id, :message => @order_string.chomp(', '), :currency => 'EUR'
        )
        if @order.blank? || @gateway.blank?
          flash[:error] = I18n.t("Invalid arguments")
          redirect_to :back
        else
          render :action => :show
        end
      end

      def success
        @order =  Order.find(params[:VK_STAMP].to_i)
        raise GatewayError, "Not found order" unless @order
        @payment = @order.payments.first
        @payment.started_processing!
        payment_response = get_payment_response(params)
        raise GatewayError, "Payment error, please contact website administrator" unless params[:VK_REF].to_i == Ipizza::Util.sign_731(@order.id.to_i).to_i

        logger.debug "Payment response: #{payment_response.inspect}"
        raise GatewayError, "Payment verification error, please contact website administrator" unless payment_response.valid?
    
        #payment.state = "completed" #
        @payment.amount = params[:VK_AMOUNT].to_f
        @payment.save
        @payment.complete! unless @payment.state == "completed"
        @order.save!
        @order.finalize!

        session[:order_id] = nil
        flash[:notice] = I18n.t(:order_processed_successfully)
        flash[:commerce_tracking] = "nothing special"
        redirect_to order_path(@order)
      end

      def failure
        @order = Order.find_by_id(params[:VK_STAMP].to_i)
        flash.now[:error] = t("payment_fail")
        redirect_to @order.blank? ? root_url : edit_order_checkout_url(@order, :step => "payment")
          return
      end

      private
  
      def get_payment_response(params)
        raise GatewayError, "Bank not specified!"
      end
    end
end