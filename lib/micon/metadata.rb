# 
# This class intentially made using "wired and not clear code", to provide better performance.
# 
module Micon
  class Metadata
    attr_accessor :registry, :initializers, :before, :after
    
    def initialize registry, sync
      @registry, @sync = registry, sync
      @before, @after, @before_scope, @after_scope, @initializers = {}, {}, {}, {}, {}
    end
    
    def clear
      @sync.synchronize do 
        @registry.clear
        @initializers.clear
        @before.clear
        @after.clear
        @before_scope.clear
        @after_scope.clear
      end
    end
    
    def delete key
      @sync.synchronize do
        @registry.delete key
        @initializers.delete key
        @before.delete key
        @after.delete key
        @before_scope.delete key
        @after_scope.delete key
      end
    end
    
    
    # 
    # Registry
    # 
    def [] key
      @sync.synchronize{@registry[key]}
    end
    
    # def []= key, value
    #   @sync.synchronize{@registry[key] = value}
    # end
    
    def include? key
      @sync.synchronize{@registry.include? key}
    end
    
    
    # 
    # Callbacks
    # 
    def register_before key, &block
      @sync.synchronize do
        raise "you should provide block!" unless block
        (@before[key] ||= []) << block
      end
    end
    
    def register_after key, &block
      @sync.synchronize do
        raise "you should provide block!" unless block
        (@after[key] ||= []) << block
      end
    end
    
    def call_before key
      if callbacks = @before[key]
        callbacks.each{|c| c.call} 
      end
    end
    
    def call_after key, object
      if callbacks = @after[key]
        callbacks.each{|c| c.call(object)}
      end
    end


    # 
    # Scope callbacks
    # 
    def register_before_scope key, &block
      @sync.synchronize do
        raise "you should provide block!" unless block
        (@before_scope[key] ||= []) << block
      end
    end
    
    def register_after_scope key, &block
      @sync.synchronize do
        raise "you should provide block!" unless block
        (@after_scope[key] ||= []) << block
      end
    end
    
    def call_before_scope key, container
      if callbacks = @before_scope[key]
        callbacks.each{|c| c.call container}
      end
    end
    
    def call_after_scope key, container
      if callbacks = @after_scope[key]
        callbacks.each{|c| c.call container}
      end
    end
    
    def with_scope_callbacks key, container, &block
      call_before_scope key, container
      result = block.call
      call_after_scope key, container
      result
    end
    
    
    # 
    # Other
    # 
    # def inspect
    #   "Registry: " + self.registry.keys.inspect
    # end
    
    # def deep_clone
    #   m = Metadata.new @sync
    #   m.registry = {}
    #   registry.each do |k, v|
    #     m.registry[k] = v
    #   end
    #   p m
    #   m
    # end
  end
end