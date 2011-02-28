warn 'remove me'
require 'monitor'

module Micon
  module Core
    protected
      def raise_without_self message
        raise RuntimeError, message, caller.select{|path| path !~ /\/lib\/micon\//}
      end
  end
end

unless {}.respond_to? :symbolize_keys
  class Hash  
    def symbolize_keys
      r = {}
      each{|k, v| r[k.to_sym] = v}
      r
    end
  end
end