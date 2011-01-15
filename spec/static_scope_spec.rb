require 'spec_helper'

describe "Application and Instance scopes" do  
  before :each do
    Micon.clear
    Micon.metadata.clear
  end
  
  it "instance scope" do    
    Micon.register(:value, scope: :instance){"The Object"}
    
    Micon[:value].should == "The Object"
    Micon[:value].object_id.should_not == Micon[:value].object_id
  end
  
  it "application scope" do
    Micon.register(:value){"The Object"}
    
    Micon[:value].should == "The Object"
    Micon[:value].object_id.should == Micon[:value].object_id
  end

  it "application scope, outjection" do
    the_object = "The Object"
    Micon.register :value
    
    Micon[:value].should be_nil
    Micon[:value] = the_object
    Micon[:value].object_id.should == the_object.object_id
  end
  
  it "cycle reference" do
    class CycleB; end
  
    class CycleA      
      register_as :cycle_a
      inject b: :cycle_b
    end
  
    class CycleB      
      register_as :cycle_b
      inject a: :cycle_a
    end
    
    a = Micon[:cycle_a]
    b = Micon[:cycle_b]
    a.b.equal?(b).should be_true
    b.a.equal?(a).should be_true
  end        
    
  it "unregister" do      
    Micon.register(:value){"The Object"}
    Micon[:value].should == "The Object"
    
    Micon.unregister :value
    lambda{Micon[:value]}.should raise_error(/component not managed/)
  end
end