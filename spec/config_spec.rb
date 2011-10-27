require 'spec_helper'
require 'ostruct'

describe "Configuration" do
  before{self.micon = Micon::Core.new}

  it "should configure component if config provided" do
    micon.register(:logger){::OpenStruct.new}
    with_load_path "#{spec_dir}/basic/lib" do
      micon[:logger].level.should == :info
    end
  end

  it "should use custom configuration if we explicitly require config in initializer" do
    logger = Object.new
    logger.should_receive(:do_custom_initialization).with(level: :info)
    micon.register :logger do |config|
      logger.do_custom_initialization config
      logger
    end

    with_load_path "#{spec_dir}/basic/lib" do
      micon[:logger]
    end
  end

  it "should merge in order: conf <- conf.mode <- runtime <- runtime.mode" do
    micon.register(:object){::OpenStruct.new}
    with_load_path "#{spec_dir}/order/lib" do
      micon.runtime_path = "#{spec_dir}/order/app"
      micon.mode = :production
      micon[:object].tap do |o|
        o.a.should == 'object.production.yml'
        o.b.should == 'runtime.object.yml'
        o.c.should == 'runtime.object.production.yml'
      end
    end
  end
end