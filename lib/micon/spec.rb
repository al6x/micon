require 'rspec_ext'

rspec do
  def self.with_micon options = {}
    scope = options[:before] || :all
    
    old, tmp = nil
    
    before scope do      
      old = MICON
      tmp = old.clone
      tmp.initialize!
    end
    
    after scope do
      tmp.deinitialize!
      old.initialize!
    end
  end
end