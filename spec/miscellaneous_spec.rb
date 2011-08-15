require 'spec_helper'

describe "Miscellaneous" do
  with_load_path "#{spec_dir}/autoload/lib"

  before{self.micon = Micon::Core.new}
  after{remove_constants :TheRouter, :TheRad}

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

  describe "complex circullar dependencies" do
    it "should not initialize twice (from error)" do
      micon.register :kit do
        micon[:kit]
        'kit'
      end
      lambda{micon[:kit]}.should raise_error(/component :kit used before it's initialization is finished/)
    end

    it "should not initialize twice if called from dependency (from error)" do
      micon.register :environment do
        micon[:router]
        'environment'
      end

      micon.register :router, depends_on: :environment do
        'router'
      end

      -> {micon[:router]}.should raise_error(/component .* used before it's initialization is finished/)
    end

    it "should allow to use circullar dependency in :after callback" do
      check = mock
      check.should_receive(:initialized).once
      micon.register :kit do
        check.initialized
        'kit'
      end
      micon.after :kit do
        micon[:kit]
      end
      micon[:kit].should == 'kit'
    end

    it "should allow circullar dependencies in :after callback" do
      micon.register :environment do
        'environment'
      end

      micon.register :router, depends_on: :environment do
        'router'
      end

      micon.after :environment do
        micon[:router]
      end

      micon[:router]
    end
  end

  it "helper method generation" do
    micon.register :router

    micon.router?.should be_false
    micon.router = 'router'
    micon.router?.should be_true
    micon.router.should == 'router'
  end
end