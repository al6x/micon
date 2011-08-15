# The :router to be properly initialized, so we use another form of
# component registration. 
class Router
	def initialize routes; @routes = routes end
	def decode request; 
	  class_name, method = @routes[request.url]                
	  return eval(class_name), method # returning actual class
	end
end
rad.register :router do
  Router.new '/index' => ['PagesController', :index]
end