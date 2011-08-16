class Router
  attr_accessor :url_root
  
  def initialize
    @routes = {}
  end
  
  def add_route url, controller, method
    @routes[url] = [controller, method]
  end
    
  def decode url
    @routes[url] if url.include?(url_root)
  end
end