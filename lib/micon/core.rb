# Predefined scopes are: :application | :session | :instance | :"custom_name"
#
# Micons :"custom_name" are managed by 'scope_begin' / 'scope_end' methods
# 
# :"custom_name" can't be nested (it will destroy old and start new one) and always should be explicitly started!.
class Micon::Core
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
    sname = @registry[key]
  
    case sname
    when nil
      false
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
    sname = @registry[key] || autoload_component_definition(key)
  
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
  
  # def get_constant_component key      
  #   sname = @registry[key] || autoload_component_definition(key, false)
  #   
  #   case sname
  #   when nil
  #     nil        
  #   when :instance        
  #     must_be.never_called
  #   when :application        
  #     return nil unless @constants.include? key
  #     
  #     o = @application[key]          
  #     unless o
  #       return create_object(key, @application)
  #     else
  #       return o
  #     end
  #   else # custom        
  #     must_be.never_called
  #   end
  # end
  # 
  # def get_constant namespace, const
  #   original_namespace = namespace
  #   namespace = nil if namespace == Object or namespace == Module
  #   target_namespace = namespace
  # 
  #   # Name hack (for anonymous classes)
  #   namespace = eval "#{name_hack(namespace)}" if namespace
  # 
  #   class_name = namespace ? "#{namespace.name}::#{const}" : const
  # 
  #   simple_also_tried = false
  #   begin
  #     simple_also_tried = (namespace == nil)
  # 
  #     if result = get_constant_component(class_name.to_sym)
  #       if @loaded_classes.include?(class_name)
  #         raise_without_self "something wrong is goin on, constant '#{const}' in '#{original_namespace}' namespace already has been defined!"
  #       end
  #     
  #       real_namespace = namespace ? namespace : Object
  #       if real_namespace.const_defined?(const)
  #         raise_without_self "component trying to redefine constant '#{const}' that already defined in '#{real_namespace}'!"
  #       end
  #       
  #       real_namespace.const_set const, result
  #   
  #       @loaded_classes[class_name] = [real_namespace, const]
  # 
  #       return result
  #     elsif namespace
  #       namespace = Module.namespace_for(namespace.name)
  #       class_name = namespace ? "#{namespace.name}::#{const}" : const
  #     end
  #   end until simple_also_tried
  #   
  #   return nil
  # end

  def []= key, value
    raise "can't assign nill as :#{key} component!" unless value
  
    sname = @registry[key] || autoload_component_definition(key)
  
    value = case sname
    when :instance
      raise_without_self "You can't outject variable with the 'instance' sname!"
    when :application
      @application[key] = value
    else # custom
      container = @custom_scopes[sname]
      raise_without_self "Scope '#{sname}' not started!" unless container
      container[key] = value
    end
    
    @metadata.call_after key, value
    
    value
  end  

  def delete key
    sname = @registry[key] # || autoload_component_definition(key)
  
    case sname
    when nil
    when :instance
      raise_without_self "You can't outject variable with the 'instance' scope!"
    when :application
      @application.delete key
    else # Custom
      container = @custom_scopes[sname]
      # raise_without_self "Scope '#{sname}' not started!" unless container
      container.delete key if container
    end
  end  
  
  def delete_all key
    metadata.delete key
    delete key
  end

  def reset key
    delete key
    self[key]
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
    # constant = options.delete(:constant) || false
  
    raise "unknown options :#{options.keys.join(', :')}!" unless options.empty?
  
    unless @registry.object_id == @metadata.registry.object_id
      raise "internal error, reference to registry aren't equal to actual registry!" 
    end
    @metadata.registry[key] = sname
    @metadata.initializers[key] = [initializer, dependencies] #, constant]
    # if constant
    #   raise "component '#{key}' defined as constant must be a symbol!" unless key.is_a? Symbol
    #   raise "component '#{key}' defined as constant can have only :application scope!" unless sname == :application
    #   @constants[key] = true
    # end
  end

  def unregister key
    @metadata.delete key
    # @constants.delete key
  end

  def before component, options = {}, &block
    options[:bang] = true unless options.include? :bang
    raise_without_self "component :#{component} already created!" if options[:bang] and include?(component)
    @metadata.register_before component, &block
  end

  def after component, options = {}, &block
    options[:bang] = true unless options.include? :bang
    if include? component
      if options[:bang]
        raise_without_self "component :#{component} already created!"
      else
        block.call self[component]
      end
    end      
    @metadata.register_after component, &block
  end

  def before_scope sname, options = {}, &block    
    options[:bang] = true unless options.include? :bang
    raise_without_self "scope :#{sname} already started!" if options[:bang] and active?(sname)
    @metadata.register_before_scope sname, &block
  end

  def after_scope sname, options = {}, &block
    options[:bang] = true unless options.include? :bang
    raise_without_self "scope :#{sname} already started!" if options[:bang] and active?(sname)
    @metadata.register_after_scope sname, &block
  end
  
  
        
  def clone
    another = super
    %w(@metadata @application @custom_scopes).each do |name| # @loaded_classes, @constants
      value = instance_variable_get name
      another.instance_variable_set name, value.clone
    end
    another.instance_variable_set '@registry', another.metadata.registry
    another.instance_variable_set '@initialized', another.instance_variable_get('@initialized')
    another     
  end
  alias_method :deep_clone, :clone
  
  def initialize!    
    unless @initialized
      # quick access to Metadata inner variable.
      # I intentially broke the Metadata incapsulation to provide better performance, don't refactor it.
      @registry = {} # @loaded_classes, @constants = {}, {}
      @metadata = Micon::Metadata.new(@registry)
      @stack = {}
    
      @application, @custom_scopes = {}, {}
      
      @initialized = true
    end
    
    # Micon::Core is independent itself and there can be multiple Cores simultaneously. 
    # But some of it's extensions can work only with one global instance, and them need to know how to get it, 
    # the MICON constant references this global instance.
    Object.send(:remove_const, :MICON) if Object.const_defined?(:MICON)
    Object.const_set :MICON, self      
  end
  
  def deinitialize!
    Object.send(:remove_const, :MICON) if Object.const_defined?(:MICON)
    
    # @loaded_classes.each do |class_name, tuple|
    #   namespace, const = tuple
    #   namespace.send(:remove_const, const)
    # end
    # @loaded_classes.clear
  end
    
  # override it in Your framework if You need it
  # - 'app/runtime'
  # - :development, :test, :production
  attr_accessor :runtime_path, :mode_name
  
  protected    
    def autoload_component_definition key, bang = true
      begin
        load "components/#{key.to_s.gsub(/::/, '/')}.rb"
      rescue LoadError
      end
      sname = @registry[key]
      raise_without_self "'#{key}' component not managed!" if bang and !sname
      sname
    end

    def create_object key, container = nil        
      initializer, dependencies, config = @metadata.initializers[key]
      raise "no initializer for :#{key} component!" unless initializer
      
      raise "component :#{key} used before it's initialization is finished!" if @stack.include? key      
      begin
        dependencies.each{|d| self[d]}
        @metadata.call_before key 

        # we need to check container first, in complex cases (circullar dependency)
        # the object already may be initialized.
        # See "should allow to use circullar dependency in :after callback".
        @stack[key] = true
        o = (container && container[key]) || initializer.call
        
        unless config == false
          unless config          
            # loading and caching config
            config = get_config key
            config = false unless config # we use false to differentiate from nil
            @metadata.initializers[key] = [initializer, dependencies, config]
            
            apply_config o, config if config
          else
            apply_config o, config
          end                    
        end
        
        container[key] = o if container
        
        raise "initializer for component :#{key} returns nill!" unless o
      ensure
        @stack.delete key
      end
          
      @metadata.call_after key, o
      o      
    end
    
    def get_config key
      ::Micon::Config.new(self, key).load
    end
    
    def apply_config component, config
      # config already have keys like "#{k}="
      config.each{|k, v| component.send(k, v)}
    end
    
    def name_hack namespace
      if namespace
        namespace.to_s.gsub("#<Class:", "").gsub(">", "")
      else
        ""
      end
      # Namespace Hack description
      # Module.name doesn't works correctly for Anonymous classes.
      # try to execute this code:
      #
      #class Module
      #  def const_missing const
      #    p self.to_s
      #  end
      #end
      #
      #class A
      #    class << self
      #        def a
      #            p self
      #            MissingConst
      #        end
      #    end
      #end
      #
      #A.a
      #
      # the output will be:
      # A
      # "#<Class:A>"
      #
    end
end