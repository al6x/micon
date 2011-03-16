require 'spec_helper'

describe "Micelaneous" do
  with_load_path "#{spec_dir}/autoload/lib"    
  
  before do
    self.micon = Micon::Core.new
  end
  
  after do
    remove_constants :TheRouter, :TheRad
  end
  
  describe "autoloading" do  
    it "should autoload component definition" do
      micon[:some_value].should == "some_value"
    end
  
    # it 'should autoload component - constants (and nested constants)' do      
    #   TheRouter.should == "TheRouter"
    #   module ::TheRad; end
    #   TheRad::TheView.should == "TheView"
    # end
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
  
  it "helper method generation" do
    micon.register :router
    
    micon.router?.should be_false
    micon.router = 'router'
    micon.router?.should be_true
    micon.router.should == 'router'
  end
end