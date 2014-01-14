BlacklightCornell::Application.routes.draw do

  root :to => "catalog#index"

  Blacklight.add_routes(self)

  devise_for :users

  match 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
  match 'backend/holdings_short/:id' => 'backend#holdings_short', :as => 'backend_holdings_short'
  match 'backend/holdings_shorth/:id' => 'backend#holdings_shorth', :as => 'backend_holdings_shorth'
  match 'backend/holdings_shorthm/:id' => 'backend#holdings_shorthm', :as => 'backend_holdings_shorthm', :constraints => { :id => /.+/}
  match 'backend/holdings_mail/:id' => 'backend#holdings_mail', :as => 'backend_holdings_mail'
# commenting out until certain this is a dead-end route  match 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  match 'backend/feedback_mail', :to => "backend#feedback_mail"

  match 'catalog/sms' => 'catalog#sms', :as => 'catalog_sms', :via => :post
  match 'catalog/check_captcha' => 'catalog#check_captcha', :as => 'check_captcha'
  
  match '/aeon/:bibid' => 'aeon#request_aeon', :as => 'request_aeon'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  mount BlacklightCornellRequests::Engine => '/request', :as => 'blacklight_cornell_request'
end
