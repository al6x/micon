require 'spec_helper'

describe "Managed" do
  before :all do
    self.micon = Micon::Core.new
  
    class ManagedObject  
      register_as :managed_object
      inject object: :object_key

      class << self  
        inject object: :object_key
      end
    end
  end
  
  before do
    micon.clear
  end

  it "scope" do
    scope = micon.metadata[:managed_object]
    initializer, dependencies = micon.metadata.initializers[:managed_object]
    scope.should == :application
    initializer.call.should be_a(ManagedObject)
  end

  it "injection" do
    the_object = "The Object"
    micon.register(:object_key){the_object}

    ManagedObject.object.should == the_object
    o = ManagedObject.new
    o.object.should == the_object
  end
  
  it "outjection" do
    the_object = "The Object"
    micon.register(:object_key)

    -> {ManagedObject.object}.should raise_error(/no initializer/)
    ManagedObject.object = the_object
    ManagedObject.object.should == the_object
  end
  
  it "empty?" do
    micon.should be_empty
    micon[:managed_object]
    micon.should_not be_empty
  end
end