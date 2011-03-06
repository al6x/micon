require 'spec_helper'

describe "Nested custom scope" do
  before :each do
    self.micon = Micon::Core.new
  end
  
  it "with block" do
    micon.register :value, scope: :custom
    
    custom_a = {}
    micon.activate :custom, custom_a do
      micon[:value] = 'value a'
      
      custom_b = {}
      micon.activate :custom, custom_b do
        micon.should_not include(:value)
        micon[:value] = 'value b'
        micon[:value].should == 'value b'
      end
      
      micon[:value].should == 'value a'
    end
  end
  
  it "should not support nested scopes without block" do
    micon.activate :custom, {}
    -> {micon.activate :custom, {}}.should raise_error(/active/)
  end
end