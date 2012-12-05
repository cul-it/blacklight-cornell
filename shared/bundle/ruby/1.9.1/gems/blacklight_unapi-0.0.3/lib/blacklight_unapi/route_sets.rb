module BlacklightUnapi
  module RouteSets
    protected
    def catalog
      add_routes do |options|
        match 'catalog/unapi', :to => "catalog#unapi", :as => 'unapi'
      end

      super
    end
  end
end
