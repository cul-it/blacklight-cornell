module BlacklightCornellRequests
  # @author Matt Connolly

  class Holding
    
    attr_reader :id, :location, :items
    
    # Basic initializer
    # 
    # @param holdings_data [Array] Array of grouped holdings_data records
    #         Each element in the array should represent one item record
    def initialize(holdings_data)
      @id = holdings_data[0]['MFHD_ID']
      @records = parse_holdings holdings_data
    end
    
    def inspect
      puts @id
    end
    
    def parse_location data
      { :id => data['LOCATION_ID'] || nil, 
        :code => data['LOCATION_CODE'] || nil, 
        :display => data['LOCATION_DISPLAY_NAME'] || nil
      }
    end
    
    # Pass in an array of holdings records and create item records for each
    def parse_holdings data
      items = []
      data.each do |h|
        items << BlacklightCornellRequests::Item.new(h)
        # NOTE: This is initializing @location. This is the only place where it should
        # be set, but it seems a bit strange to be doing it within this other initialization
        # method. Also, this assumes that the location values are the same for each 
        # record that has the same MFHD_ID — it's only retaining the last set value. This
        # seems like it should be okay, but I could be wrong.
        @location = { :id      => h['LOCATION_ID'], 
                      :code    => h['LOCATION_CODE'], 
                      :display => h['LOCATION_DISPLAY_NAME']
                    } 
      end
      @items = items
    end
    
  end
  
end