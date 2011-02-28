require 'rspec_ext'

rspec do
  # def self.with_micon scope = :all
  #   before :each do 
  #     Micon.clear
  #   end
  #   
  #   after :each do
  #     Micon.clear
  #   end
  # 
  #   old_metadata = nil
  #   before scope do
  #     old_metadata = Micon.metadata
  #     Micon.swap_metadata old_metadata.deep_clone
  #   end
  #   
  #   after scope do
  #     Micon.swap_metadata old_metadata
  #   end
  # end
  
  def self.with_micon scope = :all
    old_metadata = nil
    
    before scope do      
      old_metadata = Micon.metadata
      Micon.swap_metadata old_metadata.deep_clone
      Micon.clear
    end
    
    after scope do
      Micon.clear
      Micon.swap_metadata old_metadata
    end
  end
end