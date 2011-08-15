require 'spec_helper'

describe "Application and Instance scopes" do  
  before{self.micon = Micon::Core.new}
  
  it "dependencies" do  
    micon.register(:another_object, depends_on: :the_object){"another_object"}
    -> {micon[:another_object]}.should raise_error(/the_object.*not managed/)
    micon.register(:the_object){"the_object"}
    micon[:another_object]
  end
  
  it "instance scope" do  
    micon.register(:value, scope: :instance){"The Object"}
  
    micon[:value].should == "The Object"
    micon[:value].object_id.should_not == micon[:value].object_id
  end
  
  it "application scope" do
    micon.register(:value){"The Object"}
  
    micon[:value].should == "The Object"
    micon[:value].object_id.should == micon[:value].object_id
  end
  
  it "should not allow to return nill in initializer" do
    micon.register(:value){nil}
    -> {micon[:value]}.should raise_error(/returns nill/)
  end
  
  it "should not allow to register component without initializer but shouldn't allow to instantiate it" do
    micon.register :value
    -> {micon[:value]}.should raise_error(/no initializer/)
  end
  
  it "should not allow to assign nill as component" do
    micon.register :value
    -> {micon[:value] = nil}.should raise_error(/can't assign nill/)
  end

  it "application scope, outjection" do
    the_object = "The Object"
    micon.register :value do
      "some_value"
    end

    micon[:value].should == "some_value"
    micon[:value] = the_object
    micon[:value].object_id.should == the_object.object_id
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
  
    a = micon[:cycle_a]
    b = micon[:cycle_b]
    a.b.equal?(b).should be_true
    b.a.equal?(a).should be_true
  end  
  
  it "unregister" do  
    micon.register(:value){"The Object"}
    micon[:value].should == "The Object"
  
    micon.unregister :value
    -> {micon[:value]}.should raise_error(/component not managed/)
  end
  
  it 'delete'
end