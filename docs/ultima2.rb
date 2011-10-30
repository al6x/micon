# This is the second version of our Ultimate Web Framework.
#
# Let's see how the [first version][ultima1] can be refactored using the [Micon][micon] Dependency Injector.
#
# But before we starting, there's also one small step - we need a way to automatically
# load ruby classes. We need it because using DI without automatic class loader is like
# using chainsaw turned off - result will be worse than with the plain old saw.
#
# Installing automatic class loader:
#
#     gem install class_loader
#
# Now we are ready to proceed.

# Setting load paths.
dir = "#{File.dirname __FILE__}/ultima2"
$LOAD_PATH << "#{dir}/lib"

# Making our classes loaded automatically.
require 'class_loader'
autoload_path "#{dir}/lib"

# Enabling the Micon, it need's to know runtime_path to find configs automatically.
require 'micon'
micon.runtime_path = dir

# There are two utility classes - `Request` and `Router` they are good candidates for
# components.

# This is the main class of our framework, in the previous version it used two utility
# classes - router and config. But this time they are components, so we don't need
# to manually configure and create it.
class Ultima
  # Making `:router` and `:request` components available as attributes.
  inject :router, :request

  # The main method of our framework, here we create request,
  # decoding url and calling controller to generate some output.
  def run url
    # We need to tell Micon about the `:request` scope, so the `:request` component will be
    # destroyed automatically.
    micon.activate :request, {} do
      self.request = Request.new url

      # Using router to get controller class and method from the url.
      # Note that You using the `:router` component as if it's just an attribute.
      controller_class, method = router.decode url

      # Creating controller and calling it to generate output.
      controller = controller_class.new

      # Note we don't need to explicitly pass the `request` to controller, it will be automatically injected.
      controller.send method
    end
  end
end

# Registering our main class as the `:ultima` component so we don't need to use it as a Singleton anymore.
micon.register(:ultima){Ultima.new}

# No need to explicitly load library and controller classes, all of them will be discowered & loaded automatically.

# No need to load config, Micon will automatically discower and load it.

# No need to manually configure router, the `router.yml` config file will be applied automatically.

# Configuring routes.
micon.router.add_route '/index', PagesController, :index

# Now all is ready and we can run our application.
url = '/index'
micon.ultima.run url

# Go to console and type `ruby docs/ultima2.rb` - You should see something
# like this:
#
#     PagesController: displaying the :index page.
#
# You can compare this version and the [first one][ultima1] and see how they are differ.
# In this version You don't care about: loading classes, creating classes, loading configs,
# applying configs, passing utility objects (passing request to controller).
#
# And all this became even more significant when the App gets bigger.

# [micon]: index.html
#
# [ultima1]: ultima1.html