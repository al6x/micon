require "micon"

require 'rspec_ext'

def micon; $micon end
def micon= value
  $micon = value
  $micon.initialize!

  $micon
end