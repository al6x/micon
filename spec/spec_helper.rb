require 'rspec_ext'

require "micon"

class MicroContainer
  include Micon::Core
  include Micon::Helper
end

def micon; $micon end
def micon= value  
  $micon = value
  $micon.initialize!
  
  $micon
end