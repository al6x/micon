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

def micon; ::MICON end unless $dont_create_micon_shortcut