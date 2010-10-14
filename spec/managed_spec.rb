require 'spec_helper'

describe "Micon Managed" do
  before :all do
    Micon.metadata.clear
    
    class ManagedObject      
      register_as :managed_object
      inject :object => :object_key

      class << self        
        inject :object => :object_key
      end
    end
  end
  
  before :each do
    Micon.clear
  end

  it "scope" do
    scope = Micon.metadata[:managed_object]
    initializer, dependencies = Micon.metadata.initializers[:managed_object]
    scope.should == :application
    initializer.call.should be_a(ManagedObject)
  end

  it "injection" do
    the_object = "The Object"
    Micon.register(:object_key){the_object}

    ManagedObject.object.should == the_object
    o = ManagedObject.new
    o.object.should == the_object
  end
  
  it "outjection" do
    the_object = "The Object"
    Micon.register(:object_key)

    ManagedObject.object.should be_nil    
    ManagedObject.object = the_object
    ManagedObject.object.should == the_object
  end
  
  it "empty?" do
    Micon.should be_empty
    Micon[:managed_object]
    Micon.should_not be_empty
  end
end