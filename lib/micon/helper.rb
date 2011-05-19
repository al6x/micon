# 
# Generates helper methods for Micon,
# so you can use micon.config instead of micon[:config]
#
module Micon::Helper    
  def method_missing m, *args, &block
    super if args.size > 1 or block
    
    key = m.to_s.sub(/[?=]$/, '').to_sym
    self.class.class_eval do
      define_method key do
        self[key]
      end
    
      define_method "#{key}=" do |value|
        self[key] = value
      end
    
      define_method "#{key}?" do
        include? key
      end
    end
    
    send m, *args
  end
end