class Class
  # Usage:
  #     register_as :session, scope: :request
  #     register_as :loggger
  def register_as *args
    ::MICON.register(*args){self.new}
  end
end

Module.class_eval do
  # Usage: `inject :logger` or `inject logger: :logger`.
  def inject *attributes
    options = attributes.last.is_a?(Hash) ? attributes.pop : {}
    attributes.each{|name| options[name] = name}

    options.each do |attr_name, component_name|
      unless attr_name.is_a? Symbol
        ::MICON.raise_without_self "attribute name #{attr_name} should be a Symbol!"
      end

      define_method(attr_name){::MICON[component_name]}
      define_method("#{attr_name}="){|component| ::MICON[component_name] = component}
      define_method("#{attr_name}?"){::MICON.include? component_name}
    end
  end
end