module Micon
end

%w{
  support
  
  metadata
  core
  helper
  
  module
  class
}.each{|f| require "micon/#{f}"}