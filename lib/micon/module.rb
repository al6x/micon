Module.class_eval do
  # Usage: `inject logger: :logger`.
  def inject attributes
    ::MICON.raise_without_self "Invalid argument!" unless attributes.is_a? Hash
    attributes.each do |name, specificator|
      ::MICON.raise_without_self "Attribute name should be a Symbol!" unless name.is_a? Symbol

      define_method(name){::MICON[specificator]}
      define_method("#{name}="){|value| ::MICON[specificator] = value}
      define_method("#{name}?"){::MICON.include? specificator}
    end
  end
end