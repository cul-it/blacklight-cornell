# Useful assertions not provided by minitest-spec

def assert_present(arg, msg = nil)
  msg ||= "#{arg.inspect} is empty or not present"

  is_present = arg.respond_to?(:empty?) ? !arg.empty? : !!arg

  assert is_present, msg
end

def assert_length(length, array, msg = nil)
  msg ||= "Expected #{array.inspect} to be length #{length}"

  assert (array.respond_to?(:length) && array.length == length), msg
end

def assert_include(collection, item, msg = nil)
  assert_respond_to(collection, :include?, "The collection must respond to :include?.")
    
  msg ||= "#{collection.inspect} expected to include #{item.inspect}"

  assert collection.include?(item), msg
end