# Micon IoC assembles and manages Your Application

Micon is infrastructural component, invisible to user and it's main goal is to simplify development. It reduces complex monolithic application to set of simple low coupled components.

Concentrate on business logic and interfaces and Micon will provide automatic configuration, life cycle management and dependency resolving.

Technically it's [IoC][ioc] like framework with components, callbacks, scopes and bijections, inspired by Spring and JBoss Seam.

Is it usefull, is there any real-life application? - I'm using it as a heart of my [web framework][rad_core], this sites http://robotigra.ru, http://ruby-lang.info for example powered with it.

## Usage

Let's suppose you are building the Ruby on Rails clone, there are lots of modules let's try to deal with them

``` ruby
# Let's suppose that we want to build the Rails clone,
# there will be lot's of components - logger, controllers, router, ...

require 'micon'

# Handy shortcut to access the IoC API (this is optional and You can omit it).
def micon; MICON end

# Let's define some components.
# The :logger is one per application, it's a static component (like singleton).
class Logger
  register_as :logger
  attr_accessor :log_file_path
  def info msg
    puts "#{msg} (writen to #{log_file_path})" unless defined?(RSpec)
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
# by declaring it's :scope.
# And, we don't know beforehead what it actully will be, for different
# request there can be different controllers,
# so, here we just declaring it without any initialization block, it
# will be created at runtime later.
micon.register :controller, scope: :request

# Let's define some of our controllers, the PagesController, note - we
# don't register it as component.
class PagesController
  # We need access to :logger and :request, let's inject them
  inject logger: :logger, request: :request

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
  inject request: :request, controller: :controller

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
```

The example above is a good way to demonstrate how the IoC works in general, but it will not show two **extremelly important** aspects of IoC: **auto-discovery** and **auto-configuration**.
In real-life scenario You probably will use it in a little different way, as will be shown below, and utilize these important features (there's a short article about why these features are important [You underestimate the power of IoC][article]).

I would like to repeat it one more time - **auto-discovery and auto-configuration is extremelly important features** of the IoC, don't ignore them.

Below are the same example but done with utilizing these features, this is how the Micon IoC is supposed be used in the real-life scenario. As You can see it's almost empty, because all the components are auto-discovered, auto-loaded and auto-configured. Components are located in the [examples/web_framework2/lib/components](https://github.com/alexeypetrushin/micon/blob/master/examples/web_framework2/lib/components) folder.

Note also, that this time logger convigured automatically, with the logger.yml configuration file.

``` ruby
# Please examine the 'web_framework1.rb' example before proceeding with this one.

# Let's suppose that we want to build the Rails clone,
# there will be lot's of components - logger, controllers, router, ...

# In this example we also need another tool that automatically find & load classes.
require 'micon'
require 'class_loader'

# Handy shortcut to access the IoC API (this is optional and You can omit it).
def micon; MICON end

# Auto-discovering:
#
# All components (:logger, :router, :request, :controller) are defined in
# the web_framework2/lib/components folder.
# All classes (PagesController, RackAdapter) are
# located in web_framework2/lib folder.
#
# Note that there will be no any "require 'xxx'" clause, all components and
# classes will be loaded and dependecies be resolved automatically.

# Adding libraries to load path (in order to load components automatically).
lib_dir = "#{File.dirname(__FILE__)}/web_framework2/lib"
$LOAD_PATH << lib_dir

# Adding libraries to autoload path (in order to load classes automatically).
autoload_path lib_dir

# Auto-configuring
#
# Remember our manual configuration of "logger.log_file_path" from
# the previous example?
# This time it will be configured automatically, take a look at
# the web_framework2/lib/components/logger.yml file.
#
# Note, that there are also logger.production.yml, Micon is smart
# and will merge configs in the following order:
# logger.yml <- logger.<env>.yml <- <runtime_path>/config/logger.yml
# (If you define :environment and :runtime_path variables).

# Let's pretend that there's a Web Server and run our application,
# You should see something like this in the console:
#   Application: processing /index
RackAdapter.new.call({})
```

For the actual code please look at [examples](https://github.com/alexeypetrushin/micon/blob/master/examples).

If You are interested in more samples, please look at the [actual components][rad_core_components] used in the Rad Core Framework.

## Note

Current wersion isn't thread-safe, and I did it intentially. Actually, the first version was implemented as thread-safe, but because there's no actual multithreading in Ruby, the only thing it does - adds complexity and performance losses, so I removed it.
But if you really need it for some reason - it can be easily done.

## Installation

``` bash
gem install micon
```

## License

Copyright (c) Alexey Petrushin http://petrush.in, released under the MIT license.

[ioc]: http://en.wikipedia.org/wiki/Inversion_of_control
[rad_core]: https://github.com/alexeypetrushin/rad_core
[rad_core_components]: https://github.com/alexeypetrushin/rad_core/tree/master/lib/components
[article]: http://ruby-lang.info/blog/you-underestimate-the-power-of-ioc-3fh