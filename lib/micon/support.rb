module Micon
  module Core
    protected
      def raise_without_self message
        raise RuntimeError, message, caller.select{|path| path !~ /\/lib\/micon\//}
      end
  end
end

class Hash  
  unless method_defined? :symbolize_keys
    def symbolize_keys
      r = {}
      each{|k, v| r[k.to_sym] = v}
      r
    end
  end
end

class Module
  unless respond_to? :namespace_for
    # TODO3 cache it?
    def self.namespace_for class_name
      list = class_name.split("::")
      if list.size > 1
        list.pop
        return eval(list.join("::"), TOPLEVEL_BINDING, __FILE__, __LINE__)
      else
        return nil
      end
    end
  end
end