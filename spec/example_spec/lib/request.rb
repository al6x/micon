# Request is also dynamic, and it also can't be created beforehead.
# We also registering it without initialization, it will be
# created at runtime later.
class Request
  attr_reader :url  
  def initialize url; @url = url end  
  def to_s; @url end
end