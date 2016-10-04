module BlacklightUnapi
  unless BlacklightUnapi.const_defined? :VERSION
    def self.version
      @version ||= File.read(File.join(File.dirname(__FILE__), '..', '..', 'VERSION')).chomp
    end

    VERSION = self.version
  end
end

