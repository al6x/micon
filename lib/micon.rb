%w{
  support
  
  metadata
  core
  helper
  
  module
  class
}.each{|f| require "micon/#{f}"}

module Micon
  extend Core
end