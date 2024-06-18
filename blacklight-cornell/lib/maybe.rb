# suggested to help with nil problems 
# http://devblog.avdi.org/2011/05/30/null-objects-and-falsiness/

class NullObject
  def method_missing(*args, &block)
    self
  end
  def to_hash; []; end
  def to_a; []; end
  def to_s; ""; end
  def to_f; 0.0; end
  def to_i; 0; end
end

def Maybe(value)
  case value
  when nil then NullObject.new
  else value
  end
end
