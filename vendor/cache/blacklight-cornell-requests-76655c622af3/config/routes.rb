BlacklightCornellRequests::Engine.routes.draw do
  
  match 'hold/:bibid' => 'request#hold', :as =>'request_hold' 
  match 'hold/:bibid/:volume' => 'request#hold', :as =>'request_hold_vol' , :constraints => { :volume => /.*/ }
  match 'recall/:bibid' => 'request#recall', :as =>'request_recall'
  match 'recall/:bibid/:volume' => 'request#recall', :as =>'request_recall_vol', :constraints => { :volume => /.*/ }
  #match 'callslip/:netid/:bibid' =>'request#callslip', :as =>'request_callslip'
  match 'l2l/:bibid' =>'request#l2l', :as =>'request_l2l'
  match 'l2l/:bibid/:volume' =>'request#l2l', :as =>'request_l2l_vol', :constraints => { :volume => /.*/ }
  match 'bd/:bibid' =>'request#bd', :as =>'request_bd'
  match 'ill/:bibid' =>'request#ill', :as =>'request_ill'
  match 'purchase/:bibid' =>'request#purchase', :as =>'request_purchase'
  match 'purchase_request/:bibid' =>'request#make_purchase_request', :as =>'make_purchase_request'
  match 'pda/:bibid' =>'request#pda', :as =>'request_pda'
  match 'circ/:bibid' =>'request#circ', :as =>'request_circ'
  match 'ask/:bibid' =>'request#ask', :as =>'request_ask'
  match 'document_delivery/:bibid/:volume' => 'request#document_delivery', :as => 'request_document_delivery', :constraints => { :volume => /.*/ }
  match 'document_delivery/:bibid' => 'request#document_delivery', :as => 'request_document_delivery'
  match 'voyager/:bibid' => 'request#make_voyager_request', :as => 'make_voyager_request', :via => :post
  match '/:bibid' => 'request#magic_request', :as => 'magic_request'
  match '/:bibid/:volume' => 'request#magic_request', :as => 'volume_request', :constraints => { :volume => /.*/ } 
end
