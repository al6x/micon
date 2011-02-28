require 'rspec_ext'

require "micon"

class MicroContainer
  include Micon::Core
end

def micon; $micon end
def micon= value  
  $micon = value
  
  # Micon::Core is independent itself and there can be multiple Cores simultaneously. 
  # But some of extensions can work only with one global instance, and them need to know how to get it, 
  # the MICON constant references this global instance.
  Object.send(:remove_const, :MICON) if Object.const_defined?(:MICON)
  Object.const_set :MICON, $micon
  
  $micon
end