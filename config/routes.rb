BlacklightCornell::Application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new

# as option causing invalid route name, already in use error
#  match 'catalog/unapi', :to => "catalog#unapi", :as => 'unapi', :via => [:get]
  match 'catalog/unapi', :to => "catalog#unapi", :via => [:get]
  
  Blacklight::Marc.add_routes(self)

  root :to => "catalog#index"

  mount Blacklight::Engine => '/'

  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  resource :catalog, only: [:index], controller: 'catalog' do
    concerns :searchable
    concerns :range_searchable

  end

resources :solr_documents, except: [:index], path: '/catalog', controller: 'catalog' do
      concerns :exportable
end

#Adding proxy controller to access external URLs like digital collections
get 'proxy/search'  
get 'proxy/facet' 
  
#get 'bookmarks/email_login_required' => 'bookmarks#email_login_required'
get 'bookmarks/show_email_login_required_bookmarks' => 'bookmarks#show_email_login_required_bookmarks'
get 'bookmarks/show_email_login_required_item/:id' => 'bookmarks#show_email_login_required_item', :as => 'email_require_login'
get 'bookmarks/show_selected_item_limit_bookmarks' => 'bookmarks#show_selected_item_limit_bookmarks'

resources :bookmarks do
  concerns :exportable

  collection do
    delete 'clear'
  end
end

  #match 'catalog/unapi', :to => "catalog#unapi", :as => 'unapi', :via => [:get]

# devise_for :users

devise_for :users, controllers: {
  omniauth_callbacks: 'users/omniauth_callbacks',
  sessions: 'users/sessions'
}

# rails 4
#You should not use the `match` method in your router without specifying an HTTP method.
#If you want to expose your action to both GET and POST, add `via: [:get, :post]` option.
#If you want to expose your action to GET, use `get` in the router:
#  Instead of: match "controller#action"
#  Do: get "controller#action"

#  get 'backend/holdings/:id' => 'backend#holdings', :as => 'backend_holdings'
#  get 'backend/holdings_short/:id' => 'backend#holdings_short', :as => 'backend_holdings_short'
#  get 'backend/holdings_shorth/:id' => 'backend#holdings_shorth', :as => 'backend_holdings_shorth'
  get 'backend/holdings_shorthm/:id' => 'backend#holdings_shorthm', :as => 'backend_holdings_shorthm', :constraints => { :id => /.+/}
  get 'backend/holdings_mail/:id' => 'backend#holdings_mail', :as => 'backend_holdings_mail'
# commenting out until certain this is a dead-end route  get 'backend/clio_recall/:id', :to => "backend#clio_recall" , :as => :clio_recall
  get 'backend/feedback_mail', :to => "backend#feedback_mail"
  post 'backend/dismiss_ie9_warning', :to => 'backend#dismiss_ie9_warning'

#ArgumentError: Invalid route name, already in use: 'catalog_email'
#You may have defined two routes with the same name using the `:as` option, or you may be overriding a route already defined by a resource with the same naming. For the latter, you can restrict the routes created with `resources` as explained here:
  #post 'catalog/sms' => 'catalog#sms', :as => 'catalog_sms' # :via => :post
  get 'catalog/check_captcha' => 'catalog#check_captcha', :as => 'check_captcha'
  get 'oclc/:id' => 'catalog#oclc_request', :as => 'oclc_request'
  get 'backend/cuwebauth' => 'backend#authenticate_cuwebauth', :as => 'authenticate_cuwebauth'

  resources :catalog, only:  [:post, :get]
  get 'catalog/email' => 'catalog#email', :as => 'catalog_email', :via => :post
  get 'catalog/afemail/:id' => 'catalog#afemail', :as => 'catalog_afemail'
  get 'logins' => 'catalog#logins', :as => 'catalog_logins'

  get '/browse/authors' => 'browse#authors', :as => 'browse_authors'
  get '/browse/info' => 'browse#info', :as => 'browse_info'
  get '/browse' => 'browse#index', :as => 'browse_index'
  get '/browse/heading' => 'browse#show', :as => 'browse_show'
  get '/browse_subject' => 'browse#index_subject', :as => 'browse_index_subject'
  get '/browse/heading_subject' => 'browse#show_subject', :as => 'browse_show_subject'
  get '/browse_authortitle' => 'browse#index_authortitle', :as => 'browse_index_authortitle'
  

  match '/catalog/range_limit' => 'catalog', :via => [:get, :post, :put]
  match '/aeon/:bibid' => 'aeon#request_aeon', :as => 'request_aeon', :via => [:post, :put, :get]
  get '/databases' => 'databases#index', :as => 'databases_index'
  get '/databases/title/:alpha' => 'databases#title', :as => 'databases_title'
  get '/databases/searchdb/' => 'databases#searchdb', :as => 'databases_searchdb'
  get '/databases/subject/:q' => 'databases#subject', :as => 'databases_subject'
  get '/databases/show/:id' => 'databases#show', :as => 'databases_show'
# replaced by /databases/tou
# # get '/databases/searchERMdb/' => 'databases#searchERMdb', :as => 'databases_searchERMdb'
  get '/databases/tou/:id' => 'databases#tou', :as => 'databases_tou'
  get '/catalog/tou/:id/:providercode/:dbcode' => 'catalog#tou', :as => 'catalog_tou'

  get '/databases/erm_update' => 'databases#erm_update', :as => 'erm_update'
  get '/search', :to => 'search#index', :as => 'search_index'
  match "search/:engine", :to => "search#single_search", :as => "single_search", via: [ :get ]
  get '/digitalcollections' => 'digitalcollections#index', :as => 'digitalcollections_index'
  get '/digitalcollections/searchdigreg/' => 'digitalcollections#searchdigreg', :as => 'digitalcollections_searchdigreg'

  get '/advanced', :to =>'advanced_search#index', :as => 'advanced_search_index'
  get '/edit', :to =>'advanced_search#edit', :as => 'advanced_search_edit'

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
 
  # Bookbag routes.
  put 'book_bags/add/:id' => 'book_bags#add', :as => 'add_pindex', :constraints => { :id => /.+/}
  get 'book_bags/add/:id' => 'book_bags#add', :as => 'add_index', :constraints => { :id => /.+/}
  get 'book_bags/addbookmarks' => 'book_bags#addbookmarks', :as => 'addbookmarks_index'
  #get 'backend/holdings_shorthm/:id' => 'backend#holdings_shorthm', :as => 'backend_holdings_shorthm', :constraints => { :id => /.+/}
  delete 'book_bags/add/:id' => 'book_bags#delete', :as => 'delete_d_index', :constraints => { :id => /.+/}
  get 'book_bags/delete/:id' => 'book_bags#delete', :as => 'delete_index', :constraints => { :id => /.+/}
  get 'book_bags/index(.:format)'
  get 'book_bags/citation'
  get 'book_bags/clear' => 'book_bags#clear'
  match 'book_bags/email', via: [:get, :post]
  get 'book_bags/endnote(.:format)' => 'book_bags#endnote'
  get 'book_bags/ris(.:format)' => 'book_bags#ris'



  mount BlacklightCornellRequests::Engine => '/request', :as => 'blacklight_cornell_request'
  mount MyAccount::Engine => '/myaccount', :as => 'my_account'
end
