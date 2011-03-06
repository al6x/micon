require 'rspec_ext'

require "micon"

module Micon
  class Core
    include Helper
  end
end

def micon; $micon end
def micon= value  
  $micon = value
  $micon.initialize!
  
  $micon
end