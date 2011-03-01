class Module  
  # 
  # inject attribute: :session
  # 
  def inject attributes
    ::MICON.raise_without_self "Invalid argument!" unless attributes.is_a? Hash
    attributes.each do |name, specificator|
      ::MICON.raise_without_self "Attribute name should be a Symbol!" unless name.is_a? Symbol        
  
      if [Class, Module].include? specificator.class
        specificator = specificator.name
      elsif specificator.is_a? Symbol
        specificator = ":#{specificator}"
      else
        specificator = "\"#{specificator}\""
      end

      script = <<-RUBY
def #{name}
  ::MICON[#{specificator}]
end

def #{name}= value
  ::MICON[#{specificator}] = value
end

def #{name}?
  ::MICON.include? #{specificator}
end
      RUBY
      
      self.class_eval script, __FILE__, __LINE__
    end
  end 
  
  
  # 
  # Hook to use Constants as Components
  # 
  if defined? ::ClassLoader
    text = <<-TEXT
It seems that ClassLoader already defined, but it supposed to be activated after the Micon, otherwise it can cause performance loss!
Micon.const_missing extension should be included before than ClassLoader.const_missing otherwise the Micon.const_missing will be 
called (and will ping file system) for every loaded class!
    TEXT
    warn text
  end
  
  alias_method :const_missing_without_micon, :const_missing
  protected :const_missing_without_micon
  def const_missing const
    if value = ::MICON.get_constant(self, const)
      value
    else
      const_missing_without_micon const
    end
  end
end