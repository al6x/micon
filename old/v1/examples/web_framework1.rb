# Let's suppose that we want to build the Rails clone,
# there will be lot's of components - logger, controllers, router, ...

require 'micon'

# Handy shortcut to access the IoC API (this is optional and You can omit it).
def micon; MICON end

# Let's define some components.
# The :logger is one per application, its a static component (like singleton).
class Logger
  register_as :logger
  attr_accessor :log_file_path
  def info msg
    puts "#{msg} (writen to #{log_file_path})"
  end
end

# To demostrate basics of working with compnents let's configure our :logger
# explicitly (in the next example, it will be configured automatically).
micon.logger.log_file_path = '/tmp/web_framework.log'

# The :router requires complex initialization, so we use
# another form of component registration.
class Router
  def initialize routes; @routes = routes end
  def decode request;
    class_name, method = @routes[request.url]
    return eval(class_name), method # returning actual class
  end
end
micon.register :router do
  Router.new '/index' => ['PagesController', :index]
end

# The :controller component should be created and destroyed dynamically,
# for each request, we specifying that component is dynamic
# by declaring its :scope.
# And, we don't know beforehead what it actully will be, for different
# request there can be different controllers,
# so, here we just declaring it without any initialization block, it
# will be created at runtime later.
micon.register :controller, scope: :request

# Let's define some of our controllers, the PagesController, note - we
# don't register it as component.
class PagesController
  # We need access to :logger and :request, let's inject them
  inject :logger, :request

  def index
    # Here we can use injected component
    logger.info "Application: processing #{request}"
  end
end

# Request is also dynamic, and it also can't be created beforehead.
# We also registering it without initialization, it will be
# created at runtime later.
class Request
  attr_reader :url
  def initialize url; @url = url end
  def to_s; @url end
end
# Registering without initialization block.
micon.register :request, scope: :request

# We need to integrate our application with web server, for example with the Rack.
# When the server receive web request, it calls the :call method of our RackAdapter
class RackAdapter
  # Injecting components
  inject :request, :controller

  def call env
    # We need to tell Micon that the :request scope is started, so it will know
    # that some dynamic components should be created during this scope and
    # destroyed at the end of it.
    micon.activate :request, {} do
      # Here we manually creating the Request component
      self.request = Request.new '/index'

      # The :router also can be injected via :inject,
      # but we can also use another way to access components,
      # every component also availiable as micon.<component_name>
      controller_class, method = micon.router.decode request

      # Let's create and call our controller
      self.controller = controller_class.new
      controller.send method
    end
  end
end

# Let's pretend that there's a Web Server and run our application,
# You should see something like this in the console:
#   Application: processing /index
RackAdapter.new.call({})