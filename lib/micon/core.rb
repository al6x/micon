# Predefined scopes are: :application | :session | :thread | :instance | :"custom_name"
#
# Micons :"custom_name" are managed by 'scope_begin' / 'scope_end' methods
# 
# :"custom_name" can't be nested (it will destroy old and start new one) and always should be explicitly started!.
module Micon
  module Core
    warn 'use class variables instead of constants'
    SYNC, MSYNC = Monitor.new, Monitor.new    
    
    # 
    # Initialization
    # It should works with both :extend, and :include, and because of this there's such a complex initialization
    # 
    def initialize *a, &b
      super *a, &b      
      initialize_micon_core
    end
    
    def self.extended target            
      target.initialize_micon_core
    end
  
    
    attr_accessor :metadata
  
    #
    # Scope Management
    #
    def activate sname, container, &block
      raise_without_self "Only custom scopes can be activated!" if sname == :application or sname == :instance  
      raise "container should have type of Hash but has #{container.class.name}" unless container.is_a? Hash
    
      scope_with_prefix = add_prefix(sname)
      raise_without_self "Scope '#{remove_prefix(sname)}' already active!" if !block and Thread.current[scope_with_prefix]
    
      if block
        begin
          outer_container_or_nil = Thread.current[scope_with_prefix]
          Thread.current[scope_with_prefix] = container
          @metadata.with_scope_callbacks sname, container, &block
        ensure
          Thread.current[scope_with_prefix] = outer_container_or_nil
        end
      else        
        # not support nested scopes without block
        Thread.current[scope_with_prefix] = container
        @metadata.call_before_scope sname, container
      end
    end
  
    def deactivate sname
      raise_without_self "Only custom scopes can be deactivated!" if sname == :application or sname == :instance
    
      scope_with_prefix = add_prefix(sname)      
      raise_without_self "Scope '#{sname}' not active!" unless container = Thread.current[scope_with_prefix]
    
      @metadata.call_after_scope sname, container
      Thread.current[scope_with_prefix] = nil
      container
    end
  
    def active? sname
      if sname == :application or sname == :instance
        true
      else
        Thread.current.key?(add_prefix(sname))
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
      sname = MSYNC.synchronize{@_r[key]} || autoload(key)
    
      case sname
      when :instance
        true
      when :application
        SYNC.synchronize do
          @application.include? key
        end
      else # custom
        container = Thread.current[sname]
        return false unless container
        container.include? key
      end
    end
  
    def [] key
      sname = MSYNC.synchronize{@_r[key]} || autoload(key)
    
      case sname
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
        container = Thread.current[sname]
        raise_without_self "Scope '#{remove_prefix(sname)}' not started!" unless container
        o = container[key]
        unless o
          return create_object(key, container) 
        else
          return o
        end
      end
    end
  
    def []= key, value
      raise "can't assign nill as :#{key} component!" unless value
    
      sname = MSYNC.synchronize{@_r[key]} || autoload(key)
    
      case sname
      when :instance
        raise_without_self "You can't outject variable with the 'instance' sname!"
      when :application
        SYNC.synchronize{@application[key] = value}
      else # Custom
        container = Thread.current[sname]
        raise_without_self "Scope '#{remove_prefix(sname)}' not started!" unless container
        container[key] = value
      end
    end  
  
    def delete key
      sname = MSYNC.synchronize{@_r[key]} || autoload(key)
    
      case sname
      when :instance
        raise_without_self "You can't outject variable with the 'instance' scope!"
      when :application
        SYNC.synchronize{@application.delete key}
      else # Custom
        container = Thread.current[sname]
        raise_without_self "Scope '#{remove_prefix(sname)}' not started!" unless container
        container.delete key
      end
    end  
  
  
    # 
    # Metadata
    # 
    def register key, options = {}, &initializer
      raise "key should not be nil or false value!" unless key
      options = options.symbolize_keys      
    
      sname = options.delete(:scope) || :application
      sname = add_prefix(sname) unless sname == :application or sname == :instance
      dependencies = Array(options.delete(:require) || options.delete(:depends_on))
    
      options.each{|key| raise "Unknown option :#{key}!"}
    
      MSYNC.synchronize do
        unless @_r.object_id == @metadata.registry.object_id
          raise "internal error, reference to registry aren't equal to actual registry!" 
        end
        @metadata.registry[key] = sname
        @metadata.initializers[key] = [initializer, dependencies]
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
  
    def before_scope sname, &block
      @metadata.register_before_scope sname, &block
    end
  
    def after_scope sname, &block
      @metadata.register_after_scope sname, &block
    end
  
    # handy method, usually for test purposes
    def swap_metadata metadata = nil
      metadata ||= Metadata.new({}, MSYNC)
      old = self.metadata
    
      self.metadata = metadata
      @_r = metadata.registry
    
      old
    end
    
    def initialize_micon_core
      # quick access to Metadata inner variable.
      # I intentially broke the Metadata incapsulation to provide better performance, don't refactor it.
      @_r = {}

      @application, @metadata = {}, Metadata.new(@_r, MSYNC)
    end
      
    protected    
      def autoload key
        begin
          load "components/#{key}.rb"
        rescue LoadError
          raise_without_self "'#{key}' component not managed!"
        end
        sname = MSYNC.synchronize{@_r[key]}
        raise_without_self "'#{key}' component not managed!" unless sname
        sname
      end
  
      def create_object key, container = nil
        initializer, dependencies = MSYNC.synchronize{@metadata.initializers[key]}
        raise "no initializer for :#{key} component!" unless initializer
      
        dependencies.each{|d| self[d]}
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
            # app.register :environment, :application do
            #   p :environment
            #   'environment'
            # end
            # 
            # app.register :conveyors, :application, depends_on: :environment do
            #   p :conveyors
            #   'conveyors'
            # end
            # 
            # app.after :environment do
            #   app[:conveyors]
            # end
            # 
            # app[:conveyors]            
                      
            o = container[key]
          end
        else
          o = initializer.call
        end
        raise "initializer for component :#{key} returns nill!" unless o
              
        @metadata.call_after key, o
        o
      end
  
      def add_prefix sname
        :"mc_#{sname}"
      end
  
      def remove_prefix sname
        sname.to_s.gsub(/^mc_/, '')
      end
  end
end