require 'spec_helper'

describe "Custom Scope" do
  before :each do
    self.micon = MicroContainer.new
  end
  
  it "activate" do
    container = {}    
    micon.should_not be_active(:custom)
    micon.activate :custom, container
    micon.should be_active(:custom)

    -> {micon.activate :custom, container}.should raise_error(/active/)

    micon.deactivate :custom
    -> {micon.deactivate :custom}.should raise_error(/not active/)
    
    micon.should_not be_active(:custom)
    micon.activate :custom, container do
      micon.should be_active(:custom)
    end
  end
  
  it "check" do
    micon.register(:value, scope: :custom){"The Object"}
    -> {micon[:value]}.should raise_error(/not started/)
    -> {micon[:value] = 'value'}.should raise_error(/not started/)
  end
  
  it "get" do
    micon.register(:value, scope: :custom){"The Object"}
    container, the_object = {}, nil
    
    micon.activate :custom, container do
      micon[:value].should == "The Object"
      the_object = micon[:value]
    end
    
    micon.activate :custom, {} do
      micon[:value].object_id.should_not == the_object.object_id
    end
    
    micon.activate :custom, container do
      micon[:value].object_id.should == the_object.object_id
    end
    
    container.size.should == 1
    container[:value].should == the_object
  end
  
  it "set" do
    micon.register(:value, scope: :custom){"The Object"}
    container = {}
    
    micon.activate :custom, container do
      micon[:value].should == "The Object"
      micon[:value] = "Another Object"
      the_object = micon[:value]
    end
    
    micon.activate :custom, {} do
      micon[:value].should == "The Object"
    end
    
    micon.activate :custom, container do
      micon[:value].should == "Another Object"
    end
  end
  
  it "scope should return block value (from error)" do
    micon.activate(:custom, {}){'value'}.should == 'value'
  end
end