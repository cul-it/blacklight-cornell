BlacklightCornellRequests::Engine.routes.draw do
  
  get 'hold/:bibid' => 'request#hold', :as =>'request_hold' 
  get 'hold/:bibid/:volume' => 'request#hold', :as =>'request_hold_vol' , :constraints => { :volume => /.*/ }
  get 'recall/:bibid' => 'request#recall', :as =>'request_recall'
  get 'recall/:bibid/:volume' => 'request#recall', :as =>'request_recall_vol', :constraints => { :volume => /.*/ }
  #get 'callslip/:netid/:bibid' =>'request#callslip', :as =>'request_callslip'
  get 'l2l/:bibid' =>'request#l2l', :as =>'request_l2l'
  get 'l2l/:bibid/:volume' =>'request#l2l', :as =>'request_l2l_vol', :constraints => { :volume => /.*/ }
  get 'bd/:bibid' =>'request#bd', :as =>'request_bd'
  get 'ill/:bibid' =>'request#ill', :as =>'request_ill'
  get 'purchase/:bibid' =>'request#purchase', :as =>'request_purchase'
  get 'purchase_request/:bibid' =>'request#make_purchase_request', :as =>'make_purchase_request'
  get 'pda/:bibid' =>'request#pda', :as =>'request_pda'
  get 'circ/:bibid' =>'request#circ', :as =>'request_circ'
  get 'ask/:bibid' =>'request#ask', :as =>'request_ask'
  get 'document_delivery/:bibid/:volume' => 'request#document_delivery', :as => 'request_document_delivery_with_vol', :constraints => { :volume => /.*/ }
  get 'document_delivery/:bibid' => 'request#document_delivery', :as => 'request_document_delivery'
  match 'voyager/:bibid' => 'request#make_voyager_request', :as => 'make_voyager_request',  via: [:get, :post]
  put '/:bibid' => 'request#magic_request', :as => 'magic_request_bibid'
  get '/:bibid' => 'request#magic_request', :as => 'magic_request'
  get '/:bibid/:volume' => 'request#magic_request', :as => 'volume_request', :constraints => { :volume => /.*/ } 
end
