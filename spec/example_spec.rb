require 'spec_helper'

describe "Micon Overview" do
  before do 
    self.micon = Micon::Core.new
  end
  after do    
    remove_constants :Logger, :Router, :PagesController, :Request, :RackAdapter
  end
  
  it "example" do
    # Here's our Web Framework, let's call it Rad
    
    # Let's define shortcut to access the IoC API (optional
    # but handy step). I don't know how would You like to call it, 
    # so I leave this step to You.
    class ::Object
      def rad; MICON end
    end
    
  	# let's define some components  	
    # the :logger is one per application it's a static component (like singleton)
  	class Logger
  	  register_as :logger
  	  attr_accessor :log_file_path
  		def info msg
  		  puts "#{msg} (writen to #{log_file_path})" unless defined?(RSpec)
  		end
  	end
  	
    # To demostrate basics of working with compnents let's configure our :logger
    # manually (in the next example, it will be configured automatically).
    rad.logger.log_file_path = '/tmp/rad.log'  	
    
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
	  
    # The :controller component should be created and destroyed dynamically, 
    # for each request, we specifying that component is dynamic 
    # by declaring it's :scope. 
    # And, we don't know beforehead what it actully will be, for different 
    # request there can be different controllers, 
    # so, here we just declaring it without any initialization block, it
    # will be created at runtime later.
    rad.register :controller, scope: :request

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
  	rad.register :request, scope: :request

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

    # Let's pretend that there's a Web Server and run our application,
    # You should see something like this in the console:
    #   Application: processing /index
  	RackAdapter.new.call({})
  end
  
  describe 'real-life' do
    class_loader_available = begin 
      require 'class_loader'
      require 'class_loader/spec'
      true
    rescue LoadError    
      false
    end
  
    if class_loader_available              
      with_load_path     "#{spec_dir}/lib"
      with_autoload_path "#{spec_dir}/lib"
      
      it "example" do
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
      end
    else
      warn "The 'real-life example' requires 'class_loader' gem, please install it"
    end
  end
end