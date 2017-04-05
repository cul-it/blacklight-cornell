module BlacklightCornellRequests
  # @author Matt Connolly

  class Item
    
    attr_reader :id, :mfhd_id, :enumeration, :location, :status
    attr_accessor :solrdoc
    
    # Basic initializer
    # 
    # @param options [Hash] Hash of item data values
    def initialize(options = {})
      return nil if options['ITEM_ID'].nil?
      set_options options
      @solrdoc = nil
    end
    
    def inspect
      puts "Item record #{@id} (linked to MFHD #{@mfhd_id}):"
      puts "Status: #{@status.inspect}"
      puts "Location: #{@location.inspect}"
      puts "Enumeration: #{@enumeration.inspect}"
    end
    
    # Initialize item-level fields
    def set_options options
      
      # IDs
      @id = options['ITEM_ID'] or nil
      @mfhd_id = options['MFHD_ID'] or nil
    
      # Enumeration
      if options['ITEM_ENUM'] || options['CHRON'] || options['YEAR']
        @enumeration = {
          :enum => options['ITEM_ENUM'],
          :chron => options['CHRON'],
          :year => options['YEAR']
        }
      end
      
      # location
      if options['PERM_LOCATION'] || options['TEMP_LOCATION_CODE']
        @location = {
          :perm => options['PERM_LOCATION'],
          :temp => options['TEMP_LOCATION_CODE']
        }
      end
        
      #status
      if options['ITEM_STATUS']
        @status = {
          :code => options['ITEM_STATUS'],
          :date => options['ITEM_STATUS_DATE'],
          :due  => options['CURRENT_DUE_DATE']
        }
      end
      
    end

    # Determine whether this item matches the specified volume
    # volume = {:enum, :chron, :year}
    def volume_match? volume
      @enumeration[:enum] == volume[:enum] &&
      @enumeration[:chron] == volume[:chron] &&
      @enumeration[:year] == volume[:year]
    end
    
    # Return an array of the delivery methods that can be used for this item
    def delivery_methods(patron_type)
      
      return [] unless @status   # no status == electronic item? Is this right?
      return [] unless @solrdoc  # no doc fragment == no item record (PDA item?)
      
      # Without the following line, the later const_get call fails ... not sure why
      BlacklightCornellRequests::DeliveryMethod
      
      result = []
      loan_type_code = (@solrdoc['temp_item_type_id'].blank? or @solrdoc['temp_item_type_id'] == '0') ?
           @solrdoc['item_type_id'] : 
           @solrdoc['temp_item_type_id']
      DELIVERY_METHODS.each do |m|
        method = Object.const_get("BlacklightCornellRequests::#{m}")
        result << method if method.available?(@status[:code], 
                                              DeliveryMethod.loan_type(loan_type_code),
                                              patron_type)
      end
      
      result
    
    end
  
  end
end