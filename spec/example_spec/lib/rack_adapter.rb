# We need to integrate our application with web server, for example rack.
# When the server receive web request, it calls the :call method of our RackAdapter
class RackAdapter
  # Injecting components
  inject request: :request, controller: :controller

	def call env
    # We need to tell Micon that the :request scope is started, so it will know
    # that some dynamic components should be created during this scope and 
    # destroyed at the end of it.
		rad.activate :request, {} do
      # Here we manually creating the Request component
      self.request = Request.new '/index'
  
		  # The :router also can be injected via :inject,
      # but we can also use another way to access components,
      # every component also availiable as rad.<component_name>
		  controller_class, method = rad.router.decode request
  
      # Let's create and call our controller
		  self.controller = controller_class.new
		  controller.send method
		end
	end
end