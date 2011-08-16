# Micon - silent and invisible Killer of dependencies and configs

Micon allows You easilly and transparently eliminate dependencies and configs. Usually, when You are building complex system there are following tasks should be solved:

- where the component's code is located
- in what order should it be loaded
- what configs does the component needs to be properly initialized
- where those configs are stored
- how to change configs in different environments
- where are dependencies for component and how they should be initialized
- how to replace some components with custom implementation
- how to assembly parts of application for specs/tests
- how to restore state after each spec/test (isolate it from each other)
- how to control life-cycle of dynamically created components
- connecting components to assemble an application

*By component I mean any parts of code logically grouped together.*

Micon **solves all these tasks automatically**, and has the following **price** - You has to:

- use the *register(component_name, &initialization_block)* method for component initialization
- use the *inject(component_name)* to whire components toghether
- place component definitions to the "lib/components" folder

That's all the price, not a big one, compared to the value, eh? 
That all You need to know to use 95% of it, there are also 2-3 more specific methods, but they are needed very rarelly.

Techincally Micon is sort of Dependency Injector, but because of it's simplicity and invisibility it looks like an alien compared to it's complex and bloated IoC / DI cousins.

## Basic example

``` ruby
require 'micon'
require 'logger' # standard ruby logger

micon.register(:logger){Logger.new STDOUT}

class Application
  inject logger: :logger
  
  def run
    logger.info 'running ...'
  end
end

Application.new.run
# You should see something like this in the console:
# [2011-08-16T19:09:05.921238 #24944]  INFO -- : running ...
```

Code in examples/basics.rb

## Advanced example: let's build Web Framework

This example is more complicated and requires about 3-7 minutes. 

Let's pretend that we are building an Ultimate Framework, the RoR Killer. There will be lot's of modules and dependencies, let's see how Micon can eliminate them.
There will be two steps, at the first we'll build it as usual, and at the second refactor it using Micon.

There will be following components: router, request.

``` ruby
# setting load paths
dir = File.dirname __FILE__
$LOAD_PATH << "#{dir}/lib"


# Assembling Ultima Framework
module Ultima
  class << self
    attr_accessor :router, :config
    
    def run url
      request = Request.new url
      
      controller_class, method = router.decode url
      
      controller = controller_class.new      
      controller.request = request
      controller.send method
    end
  end
end

# reading application config
require 'yaml'
Ultima.config = YAML.load_file "#{dir}/config/config.yml"

# initializing router
require 'router'
router = Router.new
router.url_root = Ultima.config['url_root']
Ultima.router = router

# loading request and controller
require 'request'
require 'controller'


# Assemblilng Application
require 'pages_controller'

Ultima.router.add_route '/index', PagesController, :index


# Let's run it
Ultima.run '/index'
# You should see something like this in the console:
# PagesController: displaying the :index page.
```

Code in examples/ultima1/run.rb

Below are the same example but done with Micon. As You can see there's no any assembling or configuration code, because all the components are auto-discovered, auto-loaded and auto-configured.

``` ruby
# Assembling Ultima Framework
# All components: router, request, controller will be automatically loaded & configured.
class Ultima
  inject router: :router
  
  def run url
    # we need to tell Micon about the :request scope, so the Request will be
    # created & destroyed during this scope automatically.
    micon.activate :request, {} do
      request = Request.new url
    
      controller_class, method = router.decode url
    
      controller = controller_class.new
      # no need to explicitly set request, it will be automatically injected
      controller.send method
    end
  end
end
micon.register(:ultima){Ultima.new}

# No need for 'requre', all classes will be discowered & laoded automatically

# No need for config, Micon will automatically discower config/router.yml

# No need for manual router configuring, router.yml config will be applied automatically


# Assemblilng Application
# Controller will be loaded automatically
micon.router.add_route '/index', PagesController, :index


# Let's run it
micon.ultima.run '/index'
# You should see something like this in the console:
# PagesController: displaying the :index page.
```

Code in examples/ultima2/run.rb

## More samples

If You are interested in more samples, please take a look at the [actual components][rad_core_components] used in the Rad Core Web Framework.

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