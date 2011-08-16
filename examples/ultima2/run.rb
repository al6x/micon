# setting load paths (we also using automatic class loader)
dir = File.dirname __FILE__
$LOAD_PATH << "#{dir}/lib"

require 'class_loader'
autoload_path "#{dir}/lib"

require 'micon'
micon.runtime_path = dir


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