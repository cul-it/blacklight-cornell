module BorrowDirect
  module Util
    # A utility method that lets you access a nested hash, 
    # returning nil if any intermediate hashes are unavailable. 
    def hash_key_path(hash, *path)
      result = nil

      path.each do |key|
        return nil unless hash.respond_to? :"[]"
        result = hash = hash[key]
      end

      return result
    end
    module_function :hash_key_path

  end
end
