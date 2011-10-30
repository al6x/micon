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

# Let's pretend that there's a Web Server and run our application,
# You should see something like this in the console:
#   Application: processing /index
RackAdapter.new.call({})