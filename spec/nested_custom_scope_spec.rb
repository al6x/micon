require 'spec_helper'

describe "Micon nested custom scope" do
  before :each do
    Micon.clear
    Micon.metadata.clear
  end
  
  it "with block" do
    Micon.register :value, scope: :custom
    
    custom_a = {}
    Micon.activate :custom, custom_a do
      Micon[:value] = 'value a'
      
      custom_b = {}
      Micon.activate :custom, custom_b do
        Micon[:value].should be_nil
        Micon[:value] = 'value b'
        Micon[:value].should == 'value b'
      end
      
      Micon[:value].should == 'value a'
    end
  end
  
  it "should not support nested scopes without block" do
    Micon.activate :custom, {}
    lambda{Micon.activate :custom, {}}.should raise_error(/active/)
  end
end