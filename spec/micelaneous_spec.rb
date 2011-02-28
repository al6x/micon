require 'spec_helper'

describe "Micelaneous" do
  with_load_path "#{spec_dir}/autoload/lib"
  
  before :each do
    self.micon = MicroContainer.new
  end
  
  it "swap_metadata" do
    micon.register :the_object
    micon.metadata[:the_object].should_not be_nil
    micon.instance_variable_get("@registry").should include(:the_object)
    
    old_metadat = micon.swap_metadata
    
    micon.metadata[:the_object].should be_nil
    micon.instance_variable_get("@registry").should_not include(:the_object)
    
    micon.swap_metadata old_metadat
    micon.metadata[:the_object].should_not be_nil
    micon.instance_variable_get("@registry").should include(:the_object)
  end  
  
  it "should autoload component definitions if not specified" do
    micon[:router].should == "router"
  end
  
  it "dependencies" do        
    micon.register(:another_object, depends_on: :the_object){"another_object"}
    -> {micon[:another_object]}.should raise_error(/the_object/)
    micon.register(:the_object){"the_object"}
    micon[:another_object]
  end
  
  it "should not initialize twice (from error)" do
    check = mock
    check.should_receive(:environment).once.ordered
    check.should_receive(:router).once.ordered
    
    micon.register :environment do
      check.environment
      'environment'
    end
    
    micon.register :router, depends_on: :environment do
      check.router
      'router'
    end
    micon.after :environment do
      # some code that needs :router
      micon[:router]
    end    
    
    micon[:router]
  end  
end