def p; end
require 'spec_helper'

describe "Configuration" do    
  before{self.micon = Micon::Core.new}
  after{micon.runtime_path = nil}
  
  it "should configure component if config provided" do
    micon.register(:logger){OpenStruct.new}    
    with_load_path "#{spec_dir}/basic/lib" do      
      micon[:logger].level.should == :info
    end
  end
  
  it "should merge in order: conf <- conf.mode <- runtime <- runtime.mode" do
    micon.register(:object){OpenStruct.new}
    with_load_path "#{spec_dir}/order/lib" do    
      micon.runtime_path = "#{spec_dir}/order/app"
      micon.mode_name = :production
      micon[:object].tap do |o|
        o.a.should == 'object.production.yml'
        o.b.should == 'runtime.object.yml'
        o.c.should == 'runtime.object.production.yml'
      end
    end
  end
end