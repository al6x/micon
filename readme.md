# Assembles and manages pieces of Your Application

Micon is infrastructural component, invisible to user and it's main goal is to simplify development. It reduces complex monolithic application to set of simple low coupled components. 

Concentrate on business logic and interfaces and Micon will provide automatic configuration, life cycle management and dependency resolving.

Technically it's [IoC][ioc] like framework with components, callbacks, scopes and bijections, inspired by Spring and JBoss Seam.

Is it usefull, is there any real-life application? - I'm using it as a heart of my [web framework][rad_core], this sites http://robotigra.ru, http://ruby-lang.info for example powered with it.

## Usage
	
Let's suppose you are building the Ruby on Rails clone, there are lots of modules let's try to deal with them

``` ruby
require 'micon'
def app; MICON end

# static (singleton) components
class Environment
	register_as :environment
end

class Logger
	register_as :logger
	
	def info msg; end
end	

class Router
	register_as :router
	
	def parse rote_filename
	  # do something
	end
end

# callbacks, we need to parse routes right after environment is initialized
app.after :environment do
	app[:router].parse '/config/routes.rb'
end

# dynamic components, will be created and destroyed for every request
class Request
	register_as :request, scope: :request
end

class Application
	# injecting components into attributes
	inject request: :request, logger: :logger

	def do_business
		# now we can use injected component
		do_something_with request
		logger.info 'done'
	end
	
	def do_something_with request; end
end

# Web Server / Rack Adapter
class RackAdapter
	def call env		
		# activating new request scope, the session component will be created and destroyed automatically
		app.activate :request, {} do
			Application.new.do_business
		end
	end
end    

RackAdapter.new.call({})
```

The example above is a good way to demonstrate how the IoC works in general, but it will not show two **extremelly important** aspects of IoC: **auto-discovery** and **auto-configuration**.

In real-life scenario You should use it in a little other way, as will be shown below and utilize these important features.
Without using these features IoC is almost useless, and can even make Your code more complicated instead of simplifying it.

I would like to repeat it one more time - **if You don't use auto-discovery and auto-configuration then the IoC is almost useless**, is like to trying to saw with the chainsaw turned off (here's more details http://ruby-lang.info/blog/you-underestimate-the-power-of-ioc-3fh).

Belowa are the same example but done with utilizing these features, this is how the Micon IoC should be used in real-life scenario. As You can see it's almost empty, because all the components are auto-discovered, auto-loaded and auto-configured. Components are located in the [spec/example_spec/lib](https://github.com/alexeypetrushin/micon/blob/master/spec/example_spec/lib): folder.

``` ruby
# Here's our Web Framework, let's call it Rad

# Let's define shortcut to access the IoC API (optional
# but handy step). I don't know how would You like to call it, 
# so I leave this step to You.
class ::Object
  def rad; MICON end
end

# Auto-discovering:
# 
# All components (:logger, :router, :request, :controller) are 
# defined in spec/example_spec/lib/components folder.
# All classes (PagesController, RackAdapter) are
# located in spec/example_spec/lib folder.
#         
# Note that there's no any "require 'xxx'" clause, all components and
# classes are loaded and dependecies are resolved automatically.

# Auto-configuring
# 
# Remember our manual configuration of "logger.log_file_path" from 
# the previous example?
# This time it will be configured automatically, take a look at
# the spec/example_spec/lib/components/logger.yml file.
# 
# Note, that there are also logger.production.yml, configs are smart
# and are merged in the following order:
# logger.yml <- logger.<env>.yml <- <runtime_path>/config/logger.yml
# (If you define :environment and :runtime_path variables).
            	  
# Let's pretend that there's a Web Server and run our application,
# You should see something like this in the console:
#   Application: processing /index
RackAdapter.new.call({})
```
	
For the actual code please look at [spec/example_spec.rb](https://github.com/alexeypetrushin/micon/blob/master/spec/example_spec.rb)

## Note

Current wersion isn't thread-safe, instead it supported evented IO (EventMachine).
Actually I implemented first wersion as thread-safe, but because there's no actual multithreading in Ruby, the only thing it does - adds complexity and performance losses, so I removed it.
But if you need it it can be easily done.
	
## Installation

``` bash
gem install micon
```
	
## License

Copyright (c) Alexey Petrushin http://petrush.in, released under the MIT license.

[ioc]: http://en.wikipedia.org/wiki/Inversion_of_control
[rad_core]: https://github.com/alexeypetrushin/rad_core