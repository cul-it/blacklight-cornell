require 'test/unit'

class TestBareRubyStrings < Test::Unit::TestCase

 # The file bare_cp866.txt has in it a phrase encoded in cp866,
 # that if it were translated to utf8 would be:
 # "Междунар. новости мира пластмасс\n"
 #
 # The first few bytes of that in utf8 are:
 # "\xD0\x9C\xD0\xB5"
 # 
 # In cp866 as it is on disk, it's first few bytes are "\x8C\xA5"

 def test_read_cp866_with_external_encoding
   return
   file = File.open("test/bare_cp866.txt", "r:cp866")
   string = file.read

   assert_equal "IBM866", string.encoding.name

   cp866_binary = string.dup.force_encoding("binary")
   assert cp866_binary.start_with?( "\x8C\xA5".force_encoding("binary")  )
   
   transcoded = string.encode("UTF-8")
   assert_equal "UTF-8", transcoded.encoding.name

   utf8_binary = transcoded.dup.force_encoding("binary")

   assert utf8_binary.start_with?( "\xD0\x9C\xD0\xB5".force_encoding("binary"))
 end

 def test_read_cp866_binary_all_the_way
   # tell ruby to treat it as binary binary binary
   file = File.open("test/bare_cp866.txt", :external_encoding => "binary", :internal_encoding => "binary")

   string = file.read

   # we should get the same bytes that were on disk, right?
   assert string.start_with?( "\x8C\xA5".force_encoding("binary"))
 end


end 
