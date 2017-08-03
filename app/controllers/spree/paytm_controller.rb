module Spree
  class PaytmController < Spree::StoreController
    protect_from_forgery only: :index

    def index
      payment_method = Spree::PaymentMethod.find(params[:payment_method_id])
      order = Spree::Order.find_by_number!(params[:order])
      @param_list = Hash.new
      @param_list['MID'] = payment_method.preferred_merchant_id
      @param_list['INDUSTRY_TYPE_ID'] = payment_method.preferred_industry_type_id
      @param_list['CHANNEL_ID'] = payment_method.preferred_channel_id
      @param_list['WEBSITE'] = payment_method.preferred_website
      @param_list['REQUEST_TYPE'] = payment_method.request_type
      @param_list['ORDER_ID'] = payment_method.txnid(order)
      @param_list['TXN_AMOUNT'] = order.total.to_s
      @param_list['CALLBACK_URL'] = PAYTM_CALLBACK_URL

      if(address = order.bill_address || order.ship_address)
        phone = address.phone
      end
      #if user is not loggedin, Passing phone as customer id
      cust_id = spree_current_user.nil? ? phone : spree_current_user.id
      @param_list['CUST_ID'] = cust_id
      @param_list['MOBILE_NO'] = phone
      @param_list['EMAIL'] = order.email

      checksum = payment_method.new_pg_checksum(@param_list)
      @param_list['CHECKSUMHASH'] = checksum
      @paytm_txn_url = payment_method.txn_url
    end

    def confirm
      paytmparams = Hash.new
      keys = params.keys
      keys.each do |k|
        paytmparams[k] = params[k]
      end

      paytmparams.delete("CHECKSUMHASH")
      paytmparams.delete("controller")
      paytmparams.delete("action")

      @order = Spree::Order.find_by_number!(paytmparams["ORDERID"])
      if paytmparams["STATUS"] == "TXN_SUCCESS"
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        @order.complete
        redirect_to completion_route
      else
        @order.next
        redirect_to checkout_state_path(@order.state)
      end
    end

    private
    def completion_route
      spree.order_path(@order)
    end
  end
end
