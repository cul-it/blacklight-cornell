# encoding: utf-8

# 1.9.3p0 :005 > 0x8D.chr.force_encoding("cp866").encode("UTF-8")
utf8 = "Н".force_encoding("UTF-8")

puts "There's a cyrillic letter that looks kinda like a capital H. Here's what it looks like in unicode: Н"

puts "In unicode, that's byte array: " + utf8.bytes.to_a.inspect

puts "We're gonna use String#encode to convert it to an IBM866 encoding, also known as cp866, an encoding sometimes used in Russia."

 
puts "  `utf8.encode(\"IBM866\")`"

cp866 = utf8.encode("IBM866") 
puts cp866.bytes.to_a.inspect

exit

puts
puts "In cp866, the actual bytes are: #{cp866_phrase.bytes.to_a.inspect}"
puts

puts "We're going to write the cp866 string to disk, using binary:binary to try and make sure we get the bytes to disk without transcoding."

write = File.open("test_cp866.txt", "w", :internal_encoding => "binary", :external_encoding => "binary")
write.puts cp866_phrase
write.close
puts

puts "Now we're going to read it in with a File object with external_encoding set to IBM866, but no internal_encoding set."

puts
puts "Make sure we have no default internal_encoding: " + Encoding.default_internal.nil?.inspect

read = File.open("test_cp866.txt", :external_encoding => "cp866")
puts
puts "Our ruby file object should have external_encoding of IBM866: " + read.external_encoding.inspect
puts "  and internal_encoding nil: " + read.internal_encoding.inspect

puts

read_in_string = read.read
read.close

puts "The encoding of the string we read in should be IBM866: " + (read_in_string.encoding.name == "IBM866").inspect 

puts
puts "And the bytes should be the very same bytes we wrote out (which are valid cp866) " + (read_in_string.bytes.to_a[0,3] == [140, 165, 166]).inspect + " (#{read_in_string.bytes.to_a})"

puts "The above is TRUE in MRI 1.9.3, but FALSE in jruby "

