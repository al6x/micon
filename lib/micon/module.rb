class Module  
  # inject attribute: :session
  def inject attributes
    Micon.raise_without_self "Invalid argument!" unless attributes.is_a? Hash
    attributes.each do |name, specificator|
      Micon.raise_without_self "Attribute name should be a Symbol!" unless name.is_a? Symbol        
  
      if [Class, Module].include? specificator.class
        specificator = specificator.name
      elsif specificator.is_a? Symbol
        specificator = ":#{specificator}"
      else
        specificator = "\"#{specificator}\""
      end

      script = <<-RUBY
def #{name}
  ::Micon[#{specificator}]
end

def #{name}= value
  ::Micon[#{specificator}] = value
end

def #{name}?
  ::Micon.include? #{specificator}
end
      RUBY
      
      self.class_eval script, __FILE__, __LINE__
    end
  end 
end