class Micon::Core
  protected
    def raise_without_self message
      raise RuntimeError, message, caller.select{|path| path !~ /\/lib\/micon\//}
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