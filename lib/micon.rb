require 'yaml'

module Micon
end

%w{
  support

  metadata
  config
  core
  helper

  module
  class
}.each{|f| require "micon/#{f}"}

# Initializing Micon
Micon::Core.send :include, Micon::Helper
micon = Micon::Core.new
micon.initialize!