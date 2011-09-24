# This is the first version of our Ultimate Web Framework, we creating it as usual,
# without [Micon][micon] using just plain old Ruby technics.
#
# Later, in the [step two][ultima2] we'll refactor this version using [Micon][micon].

# Setting load paths.
dir = "#{File.dirname __FILE__}/ultima1"
$LOAD_PATH << "#{dir}/lib"

# This is the main class of our framework, it uses another utility
# classes like router and config.
module Ultima
  class << self
    # References to router and config.
    attr_accessor :router, :config

    # The main method of our framework, here we create request,
    # decoding url and calling controller to generate some output.
    def run url
      # Creating new request object from url.
      request = Request.new url

      # Using router to get controller class and method from the url.
      controller_class, method = router.decode url

      # Creating controller and calling it to generate output.
      controller = controller_class.new

      # Passing request to controller.
      controller.request = request
      controller.send method
    end
  end
end

# In any serious application there are always some sort of config files,
# so we also have it, reading our config file.
require 'yaml'
Ultima.config = YAML.load_file "#{dir}/config/config.yml"

# Now as in any real application we are using some property of config file
# to configure our framework, in our case we are using it to initialize router.
require 'router'
router = Router.new
router.url_root = Ultima.config['url_root']
Ultima.router = router

# We also need to load request and controller classes, located in the `.docs/ultima1/lib` folder.
require 'request'
require 'controller'

# At last all of system libraries are loaded and ready and we can load our
# application - PagesController.
require 'pages_controller'

# We also need to configure some routes.
Ultima.router.add_route '/index', PagesController, :index

# Now all is ready and we can run our application.
url = '/index'
Ultima.run url

# Go to console and type `ruby docs/ultima1.rb` - You should see something
# like this:
#
#     PagesController: displaying the :index page.
#
# So, our framework is working!
#
# Now, please take look at the [second version][ultima2] of this framework and see how it can
# be simplified by using Dependency Inejction.

# [micon]: index.html
#
# [ultima2]: ultima2.html