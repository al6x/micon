# There are 3 types of component scopes: :application, :instance and custom scope.
# Custom scopes are managed with `activate` and `deactivate` methods.
class Micon::Core
  # Scope Management.

  attr_accessor :custom_scopes

  def activate sname, container = {}, &block
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

  # Component Management.

  def include? key
    sname = @registry[key]

    case sname
    when nil
      false
    when :instance
      true
    when :application
      @application.include? key
    else # custom scope.
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
    else # custom scope.
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

    sname = @registry[key] || autoload_component_definition(key)

    value = case sname
    when :instance
      raise_without_self "You can't outject variable with the 'instance' sname!"
    when :application
      @application[key] = value
    else # custom scope.
      container = @custom_scopes[sname]
      raise_without_self "Scope '#{sname}' not started!" unless container
      container[key] = value
    end

    @metadata.call_after key, value

    value
  end

  def delete key
    sname = @registry[key]

    case sname
    when nil
    when :instance
      raise_without_self "You can't outject variable with the 'instance' scope!"
    when :application
      @application.delete key
    else # custom scope.
      container = @custom_scopes[sname]
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

  # Metadata.

  attr_accessor :metadata

  def register key, options = {}, &initializer
    raise "key should not be nil or false value!" unless key

    sname = options.delete(:scope) || :application
    dependencies = Array(options.delete(:require) || options.delete(:depends_on))

    raise "unknown options :#{options.keys.join(', :')}!" unless options.empty?

    unless @registry.object_id == @metadata.registry.object_id
      raise "internal error, reference to registry aren't equal to actual registry!"
    end
    @metadata.registry[key] = sname
    @metadata.initializers[key] = [initializer, dependencies]
  end

  def unregister key
    @metadata.delete key
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
      # Quick access to Metadata inner variable. I intentially broke
      # the Metadata incapsulation to provide better performance, don't refactor it.
      @registry = {}
      @metadata = Micon::Metadata.new(@registry)
      @stack = {}

      @application, @custom_scopes = {}, {}

      @initialized = true
    end

    # Micon::Core is independent itself and there can be multiple Cores simultaneously.
    # But some of its extensions can work only with one global instance, and them need to know how to get it,
    # the MICON constant references this global instance.
    Object.send(:remove_const, :MICON) if Object.const_defined?(:MICON)
    Object.const_set :MICON, self
  end

  def deinitialize!
    Object.send(:remove_const, :MICON) if Object.const_defined?(:MICON)
  end

  # `runtime_path` is used to search for component configurations, it may be `app/runtime` for example..
  def runtime_path; @runtime_path ||= File.expand_path('.') end
  def runtime_path= runtime_path
    runtime_path, force = runtime_path
    raise "some components has been already initialized before You set :runtime_path!" unless empty? or force
    @runtime_path = runtime_path
  end
  def runtime_path?; !!@runtime_path end

  # `mode` used to search for component configuration, examples:
  # - `app/runtime/logger.production.yml`
  # - `app/runtime/production/logger.yml`
  def mode; @mode ||= :development end
  def mode= mode
    mode, force = mode
    raise "some components has been already initialized before You set :mode!" unless empty? or force
    @mode = mode
  end
  def mode?; !!@mode end

  def development?; mode == :development end
  def production?; mode == :production end
  def test?; mode == :test end

  def development &block; block.call if development? end
  def production &block; block.call if production? end
  def test &block; block.call if test? end

  def raise_without_self message
    raise RuntimeError, message, caller.select{|path| path !~ /\/lib\/micon\//}
  end

  protected
    def autoload_component_definition key, bang = true
      begin
        require "components/#{key.to_s.gsub(/::/, '/')}"
      rescue LoadError
      end
      sname = @registry[key]
      raise_without_self "'#{key}' component not managed!" if bang and !sname
      sname
    end

    def create_object key, container = nil
      initializer, dependencies, config = @metadata.initializers[key]
      raise "no initializer for :#{key} component!" unless initializer

      raise "component :#{key} used before its initialization is finished!" if @stack.include? key
      begin
        dependencies.each{|d| self[d]}
        @metadata.call_before key

        # We need this check to detect and prevent component from been used before its initialization
        # is finished.
        @stack[key] = true

        # We need to check container first, in complex cases (circullar dependency)
        # the object already may be initialized.
        # See "should allow to use circullar dependency in :after callback".
        o = (container && container[key]) || begin
          # Loading component configuration, comparing to nil is important,
          # we use false if there's no config.
          if config == nil
            config = get_config key
            config = false unless config
            @metadata.initializers[key] = [initializer, dependencies, config]
          end

          # Use arity to determine should we apply cofig automatically or
          # component wants to apply it by themself.
          if initializer.arity == 1
            initializer.call config
          else
            o = initializer.call
            config.each{|k, v| o.send("#{k}=", v)} if config
            o
          end
        end

        # Storing created component in container.
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

    # def apply_config component, config
    #   if component.respond_to? :configure!
    #     component.configure! config
    #   else
    #     config.each{|k, v| component.send("#{k}=", v)}
    #   end
    # end
    #
    # Module.name doesn't works correctly for Anonymous classes,
    # try to execute this code:
    #
    #     class Module
    #      def const_missing const
    #        p self.to_s
    #      end
    #     end
    #
    #     class A
    #       class << self
    #         def a
    #           p self
    #           MissingConst
    #         end
    #       end
    #     end
    #
    #     A.a
    #
    # The output will be:
    #
    #     A
    #     "#<Class:A>"
    def name_hack namespace
      if namespace
        namespace.to_s.gsub("#<Class:", "").gsub(">", "")
      else
        ""
      end
    end

    # Generates helper methods, so you can use `micon.logger` instead of `micon[:logger]`
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