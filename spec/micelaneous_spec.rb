require 'spec_helper'

describe "Micelaneous" do  
  before :each do
    Micon.clear
    Micon.metadata.clear
  end
  
  it "swap_metadata" do
    Micon.register :the_object
    Micon.metadata[:the_object].should_not be_nil
    Micon.instance_variable_get("@_r").should include(:the_object)
    
    old_metadat = Micon.swap_metadata
    
    Micon.metadata[:the_object].should be_nil
    Micon.instance_variable_get("@_r").should_not include(:the_object)
    
    Micon.swap_metadata old_metadat
    Micon.metadata[:the_object].should_not be_nil
    Micon.instance_variable_get("@_r").should include(:the_object)
  end  
  
  it "dependencies" do        
    Micon.register :another_object, depends_on: :the_object
    -> {Micon[:another_object]}.should raise_error(/the_object/)
    Micon.register :the_object
    Micon[:another_object]
  end
  
  it "should not initialize twice (from error)" do
    check = mock
    check.should_receive(:environment).once.ordered
    check.should_receive(:router).once.ordered
    
    Micon.register :environment do
      check.environment
      'environment'
    end
    
    Micon.register :router, depends_on: :environment do
      check.router
      'router'
    end
    Micon.after :environment do
      # some code that needs :router
      Micon[:router]
    end    
    
    Micon[:router]
  end  
end