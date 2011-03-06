require 'spec_helper'

describe "Micon Overview" do
  before :each do
    self.micon = Micon::Core.new
  end
  
  it "sample" do
    class Object
      def app; MICON end
    end
    
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
  end
end