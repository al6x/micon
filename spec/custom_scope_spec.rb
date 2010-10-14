require 'spec_helper'

describe "Micon custom scope" do
  before :each do
    Micon.clear
    Micon.metadata.clear
  end
  
  it "activate" do
    container = {}    
    Micon.should_not be_active(:custom)
    Micon.activate :custom, container
    Micon.should be_active(:custom)

    lambda{Micon.activate :custom, container}.should raise_error(/active/)

    Micon.deactivate :custom
    lambda{Micon.deactivate :custom}.should raise_error(/not active/)
    
    Micon.should_not be_active(:custom)
    Micon.activate :custom, container do
      Micon.should be_active(:custom)
    end
  end
  
  it "check" do
    Micon.register(:value, :scope => :custom){"The Object"}
    lambda{Micon[:value]}.should raise_error(/not started/)
    lambda{Micon[:value] = nil}.should raise_error(/not started/)
  end
  
  it "get" do
    Micon.register(:value, :scope => :custom){"The Object"}
    container, the_object = {}, nil
    
    Micon.activate :custom, container do
      Micon[:value].should == "The Object"
      the_object = Micon[:value]
    end
    
    Micon.activate :custom, {} do
      Micon[:value].object_id.should_not == the_object.object_id
    end
    
    Micon.activate :custom, container do
      Micon[:value].object_id.should == the_object.object_id
    end
    
    container.size.should == 1
    container[:value].should == the_object
  end
  
  it "set" do
    Micon.register(:value, :scope => :custom){"The Object"}
    container = {}
    
    Micon.activate :custom, container do
      Micon[:value].should == "The Object"
      Micon[:value] = "Another Object"
      the_object = Micon[:value]
    end
    
    Micon.activate :custom, {} do
      Micon[:value].should == "The Object"
    end
    
    Micon.activate :custom, container do
      Micon[:value].should == "Another Object"
    end
  end
  
  it "scope should return block value (from error)" do
    Micon.activate(:custom, {}){'value'}.should == 'value'
  end
end