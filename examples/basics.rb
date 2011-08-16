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