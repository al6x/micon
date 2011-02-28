%w{
  support
  
  metadata
  core
  
  module
  class
}.each{|f| require "micon/#{f}"}

module Micon
  extend Core
end