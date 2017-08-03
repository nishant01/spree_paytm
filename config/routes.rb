Spree::Core::Engine.add_routes do
  get '/paytm', :to => "paytm#index", :as => :paytm_proceed
  match '/confirm_payment' => 'paytm#confirm', via: [:post]
  post '/paytm/cancel', :to => "paytm#cancel", :as => :paytm_cancel
end
