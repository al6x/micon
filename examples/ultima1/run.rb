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