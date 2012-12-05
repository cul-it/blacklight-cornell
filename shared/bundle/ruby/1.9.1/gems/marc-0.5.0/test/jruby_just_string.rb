# encoding: binary

# jruby 1.6.7 (ruby-1.9.2-p312) (2012-02-22 3e82bc8) (Java HotSpot(TM) 64-Bit Server VM 1.6.0_20) [linux-amd64-java]

# There is a letter in cyrillic that looks kind of like a capital
# H.  In the cp866 encoding (http://en.wikipedia.org/wiki/Code_page_866)
# it's represented by "\x8D" which is decimal 141. 
#
# In ruby 1.9, it _ought_ to be possible to have those bytes
# in a string, and tell ruby it's cp866. 

cp866 = "\x8D".force_encoding("IBM866")

# in MRI 1.9.3, if we inspect that, we get "\x8D", just like we expect.
# and if we look at #bytes.to_a, we get [141], just like we expect. 
puts cp866.inspect
puts cp866.bytes.to_a.inspect
# However, in jruby if we #inspect instead of getting "\x8D", 
# we get "\u008D" -- this is wrong, it's NOT that unicode codepoint.
# In jruby, bytes.to_a.inspect is still [141], it hasn't changed
# the bytes, but it's confused about what's going on. 

# We see this encoding confusion demonstrated if we try
# a String#encode. 
#
# MRI 1.9.3 is perfectly capable of transcoding this to UTF-8

utf8 = cp866.encode("UTF-8")
puts utf8.inspect # =>  in MRI displays cyrillic in terminal no prob
puts utf8.bytes.to_a.inspect # => in MRI [208, 157], proper bytes for utf8

# In jruby, puts utf8.inspect displays "\u008D", and
# utf8.bytes.to_a.inspect is [194, 141]. I don't know where the
# 191 came from, but it has NOT succesfully transcoded to utf8. 

# In other cases, the #encode will actually raise an illegal byte
# exception if the original bytes were not legal for UTF8 (or UTF16?) --
# but the original bytes were not meant to be considered unicode at all.

