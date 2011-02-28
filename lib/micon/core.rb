# Predefined scopes are: :application | :session | :instance | :"custom_name"
#
# Micons :"custom_name" are managed by 'scope_begin' / 'scope_end' methods
# 
# :"custom_name" can't be nested (it will destroy old and start new one) and always should be explicitly started!.
module Micon
  module Core
    # 
    # Initialization
    # It should works with both :extend, and :include, and because of this there's such a complex initialization
    # 
    def initialize *a, &b
      super *a, &b      
      _initialize_micon_core
    end
    
    def self.extended target            
      target._initialize_micon_core
    end
  
    
    #
    # Scope Management
    #
    attr_accessor :custom_scopes
    
    def activate sname, container, &block
      raise_without_self "Only custom scopes can be activated!" if sname == :application or sname == :instance  
      raise "container should have type of Hash but has #{container.class.name}" unless container.is_a? Hash
    
      raise_without_self "Scope '#{sname}' already active!" if !block and @custom_scopes[sname]
    
      if block
        begin
          outer_container_or_nil = @custom_scopes[sname]
          @custom_scopes[sname] = container
          @metadata.with_scope_callbacks sname, container, &block
        ensure
          if outer_container_or_nil
            @custom_scopes[sname] = outer_container_or_nil
          else
            @custom_scopes.delete sname
          end
        end
      else        
        # not support nested scopes without block
        @custom_scopes[sname] = container
        @metadata.call_before_scope sname, container
      end
    end
  
    def deactivate sname
      raise_without_self "Only custom scopes can be deactivated!" if sname == :application or sname == :instance
    
      raise_without_self "Scope '#{sname}' not active!" unless container = @custom_scopes[sname]
    
      @metadata.call_after_scope sname, container
      @custom_scopes.delete sname
      container
    end
  
    def active? sname
      if sname == :application or sname == :instance
        true
      else
        @custom_scopes.include? sname
      end      
    end
  
    def clear      
      @application.clear
      @custom_scopes.clear
    end
  
    def empty?
      @application.empty? and @custom_scopes.empty?
    end
  
  
    # 
    # Object Management
    # 
    def include? key
      sname = @registry[key] || autoload(key)
    
      case sname
      when :instance
        true
      when :application
        @application.include? key
      else # custom
        container = @custom_scopes[sname]
        return false unless container
        container.include? key
      end
    end
  
    def [] key
      sname = @registry[key] || autoload(key)
    
      case sname
      when :instance        
        return create_object(key)
      when :application        
        o = @application[key]          
        unless o
          return create_object(key, @application)
        else
          return o
        end
      else # custom        
        container = @custom_scopes[sname]
        raise_without_self "Scope '#{sname}' not started!" unless container
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
    
      sname = @registry[key] || autoload(key)
    
      case sname
      when :instance
        raise_without_self "You can't outject variable with the 'instance' sname!"
      when :application
        @application[key] = value
      else # custom
        container = @custom_scopes[sname]
        raise_without_self "Scope '#{sname}' not started!" unless container
        container[key] = value
      end
    end  
  
    def delete key
      sname = @registry[key] || autoload(key)
    
      case sname
      when :instance
        raise_without_self "You can't outject variable with the 'instance' scope!"
      when :application
        @application.delete key
      else # Custom
        container = @custom_scopes[sname]
        raise_without_self "Scope '#{sname}' not started!" unless container
        container.delete key
      end
    end  
  
  
    # 
    # Metadata
    # 
    attr_accessor :metadata
    
    def register key, options = {}, &initializer
      raise "key should not be nil or false value!" unless key
      options = options.symbolize_keys      
    
      sname = options.delete(:scope) || :application
      dependencies = Array(options.delete(:require) || options.delete(:depends_on))
    
      options.each{|key| raise "Unknown option :#{key}!"}
    
      unless @registry.object_id == @metadata.registry.object_id
        raise "internal error, reference to registry aren't equal to actual registry!" 
      end
      @metadata.registry[key] = sname
      @metadata.initializers[key] = [initializer, dependencies]
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
      metadata ||= Metadata.new({})
      old = self.metadata
    
      self.metadata = metadata
      @registry = metadata.registry
    
      old
    end
    
    def _initialize_micon_core
      # quick access to Metadata inner variable.
      # I intentially broke the Metadata incapsulation to provide better performance, don't refactor it.
      @registry = {}
      @metadata = Metadata.new(@registry)
      
      @application, @custom_scopes = {}, {}
    end
      
    protected    
      def autoload key
        begin
          load "components/#{key}.rb"
        rescue LoadError
          raise_without_self "'#{key}' component not managed!"
        end
        sname = @registry[key]
        raise_without_self "'#{key}' component not managed!" unless sname
        sname
      end
  
      def create_object key, container = nil
        initializer, dependencies = @metadata.initializers[key]
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
  end
end