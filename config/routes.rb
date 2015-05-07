BlacklightCornell::Application.routes.draw do

  Blacklight::Marc.add_routes(self)
  root :to => "catalog#index"

  Blacklight.add_routes(self)
  

  devise_for :users
# rails 4
#You should not use the `match` method in your router without specifying an HTTP method.
#If you want to expose your action to both GET and POST, add `via: [:get, :post]` option.
#If you want to expose your action to GET, use `get` in the router:
#  Instead of: match "controller#action"
#  Do: get "controller#action"

  get 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
  get 'backend/holdings_short/:id' => 'backend#holdings_short', :as => 'backend_holdings_short'
  get 'backend/holdings_shorth/:id' => 'backend#holdings_shorth', :as => 'backend_holdings_shorth'
  get 'backend/holdings_shorthm/:id' => 'backend#holdings_shorthm', :as => 'backend_holdings_shorthm', :constraints => { :id => /.+/}
  get 'backend/holdings_mail/:id' => 'backend#holdings_mail', :as => 'backend_holdings_mail'
# commenting out until certain this is a dead-end route  get 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  get 'backend/feedback_mail', :to => "backend#feedback_mail"

#ArgumentError: Invalid route name, already in use: 'catalog_email' 
#You may have defined two routes with the same name using the `:as` option, or you may be overriding a route already defined by a resource with the same naming. For the latter, you can restrict the routes created with `resources` as explained here: 
  #post 'catalog/sms' => 'catalog#sms', :as => 'catalog_sms' # :via => :post
  get 'catalog/check_captcha' => 'catalog#check_captcha', :as => 'check_captcha'

  resources :catalog, only:  [:post, :get]
  get 'catalog/email' => 'catalog#email', :as => 'xcatalog_email', :via => :post
  
  match '/aeon/:bibid' => 'aeon#request_aeon', :as => 'request_aeon', :via => [:post, :put, :get]
  get '/databases' => 'databases#index', :as => 'databases_index'
  get '/databases/title/:alpha' => 'databases#title', :as => 'databases_title'
  get '/databases/searchdb/' => 'databases#searchdb', :as => 'databases_searchdb'
  get '/databases/subject/:q' => 'databases#subject', :as => 'databases_subject'
  get '/databases/show/:id' => 'databases#show', :as => 'databases_show'
  get '/databases/searchERMdb/' => 'databases#searchERMdb', :as => 'databases_searchERMdb'
  
  get '/search', :to => 'search#index'#, :as => 'single_search', :via => [:post, :get]
  match "search/:engine", :to => "search#single_search", :as => "single_search", via: [ :get ]

   get '/digitalcollections' => 'digitalcollections#index', :as => 'digitalcollections_index'
  get '/digitalcollections/searchdigreg/' => 'digitalcollections#searchdigreg', :as => 'digitalcollections_searchdigreg'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   get 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   get 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
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
