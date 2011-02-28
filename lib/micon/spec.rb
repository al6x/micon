require 'rspec_ext'

rspec do
  def self.with_micon scope = :all
    old_metadata = nil
    
    before scope do      
      old_metadata = MICON.metadata
      MICON.swap_metadata old_metadata.deep_clone
      MICON.clear
    end
    
    after scope do
      MICON.clear
      MICON.swap_metadata old_metadata
    end
  end
end