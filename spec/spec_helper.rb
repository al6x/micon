require 'rspec_ext'
require 'ostruct'

require "micon"

Micon::Core.send :include, Micon::Helper

def micon; $micon end
def micon= value
  $micon = value
  $micon.initialize!

  $micon
end