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