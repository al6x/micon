# Predefined scopes are: :application | :session | :thread | :instance | :"custom_name"
#
# Micons :"custom_name" are managed by 'scope_begin' / 'scope_end' methods
# 
# :"custom_name" can't be nested (it will destroy old and start new one) and always should be explicitly started!.

module Micon
  SYNC, MSYNC = Monitor.new, Monitor.new
    
  # quick access to Metadata inner variable.
  # I intentially broke the Metadata incapsulation to provide better performance, don't refactor it.
  @_r = {} 
    
  @application, @metadata = {}, Metadata.new(@_r, MSYNC)
  
  class << self
    attr_accessor :metadata
    
    #
    # Scope Management
    #
    def activate scope, container, &block
      raise_without_self "Only custom scopes can be activated!" if scope == :application or scope == :instance  
      raise "container should have type of Hash but has #{container.class.name}" unless container.is_a? Hash
      
      scope_with_prefix = add_prefix(scope)
      raise_without_self "Scope '#{remove_prefix(scope)}' already active!" if !block and Thread.current[scope_with_prefix]
      
      if block
        begin
          outer_container_or_nil = Thread.current[scope_with_prefix]
          Thread.current[scope_with_prefix] = container
          @metadata.with_scope_callbacks scope, &block
        ensure
          Thread.current[scope_with_prefix] = outer_container_or_nil
        end
      else        
        # not support nested scopes without block
        Thread.current[scope_with_prefix] = container
        @metadata.call_before_scope scope
      end
    end
    
    def deactivate scope
      raise_without_self "Only custom scopes can be deactivated!" if scope == :application or scope == :instance
      
      scope_with_prefix = add_prefix(scope)      
      raise_without_self "Scope '#{scope}' not active!" unless container = Thread.current[scope_with_prefix]
      
      @metadata.call_after_scope scope
      Thread.current[scope_with_prefix] = nil
      container
    end
    
    def active? scope
      if scope == :application or scope == :instance
        true
      else
        Thread.current.key?(add_prefix(scope))
      end      
    end
    
    def clear      
      SYNC.synchronize{@application.clear}
      Thread.current.keys.each do |key|
        Thread.current[key] = nil if key.to_s =~ /^mc_/
      end
    end
    
    def empty?
      return false unless SYNC.synchronize{@application.empty?}
      Thread.current.keys.each do |key|
        return false if key.to_s =~ /^mc_/
      end
      return true
    end
    
    
    # 
    # Object Management
    # 
    def include? key
      scope = MSYNC.synchronize{@_r[key]}
      
      case scope
      when nil
        raise_without_self "'#{key}' component not managed!"
      when :instance
        true
      when :application
        SYNC.synchronize do
          @application.include? key
        end
      else # custom
        container = Thread.current[scope]
        return false unless container
        container.include? key
      end
    end
    
    def [] key
      scope = MSYNC.synchronize{@_r[key]}

      case scope
      when nil
        raise_without_self "'#{key}' component not managed!"
      when :instance        
        return create_object(key)
      when :application
        SYNC.synchronize do
          o = @application[key]          
          unless o
            return create_object(key, @application)
          else
            return o
          end
        end
      else # custom        
        container = Thread.current[scope]
        raise_without_self "Scope '#{remove_prefix(scope)}' not started!" unless container
        o = container[key]
        unless o
          return create_object(key, container) 
        else
          return o
        end
      end
    end
    
    def []= key, value
      scope = MSYNC.synchronize{@_r[key]}
      
      case scope
      when nil
        raise_without_self "'#{key}' component not managed!"
      when :instance
        raise_without_self "You can't outject variable with the 'instance' scope!"
      when :application
        SYNC.synchronize{@application[key] = value}
      else # Custom
        container = Thread.current[scope]
        raise_without_self "Scope '#{remove_prefix(scope)}' not started!" unless container
        container[key] = value
      end
    end    
    
    
    # 
    # Metadata
    # 
    def register key, options = {}, &initializer
      raise "key should not be nil or false value!" unless key
      options = options.symbolize_keys      
      
      scope = options.delete(:scope) || :application
      scope = Micon.add_prefix(scope) unless scope == :application or scope == :instance
      dependencies = Array(options.delete(:require) || options.delete(:depends_on))
      
      options.each{|key| raise "Unknown option :#{key}!"}
      
      MSYNC.synchronize do
        unless @_r.object_id == @metadata.registry.object_id
          raise "internal error, reference to registry aren't equal to actual registry!" 
        end
        @metadata.registry[key] = scope
        @metadata.initializers[key] = [(initializer || lambda{nil}), dependencies]
      end
    end
    
    def unregister key
      @metadata.delete key
    end
    
    def before component, &block
      @metadata.register_before component, &block
    end
    
    def after component, &block
      @metadata.register_after component, &block
    end
    
    def before_scope scope, &block
      @metadata.register_before_scope scope, &block
    end
    
    def after_scope scope, &block
      @metadata.register_after_scope scope, &block
    end
    
    # handy method, usually for test purposes
    def swap_metadata metadata = nil
      metadata ||= Metadata.new({}, MSYNC)
      old = self.metadata
      
      self.metadata = metadata
      @_r = metadata.registry
      
      old
    end
        
    protected    
      def create_object key, container = nil
        initializer, dependencies = MSYNC.synchronize{@metadata.initializers[key]}
        dependencies.each{|d| Micon[d]}
        @metadata.call_before key            
        
        if container
          unless o = container[key]
            o = initializer.call          
            container[key] = o 
          else
            # complex case, there's an circular dependency, and the 'o' already has been 
            # initialized in dependecies or callbacks
            # here's the sample case:
            # 
            # Micon.register :environment, :application do
            #   p :environment
            #   'environment'
            # end
            # 
            # Micon.register :conveyors, :application, :depends_on => :environment do
            #   p :conveyors
            #   'conveyors'
            # end
            # 
            # Micon.after :environment do
            #   Micon[:conveyors]
            # end
            # 
            # Micon[:conveyors]            
                        
            o = container[key]
          end
        else
          o = initializer.call
        end
                
        @metadata.call_after key, o
        o
      end
    
      def add_prefix scope
        :"mc_#{scope}"
      end
    
      def remove_prefix scope
        scope.to_s.gsub(/^mc_/, '')
      end
  end
end