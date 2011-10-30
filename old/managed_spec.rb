require 'spec_helper'

describe "Managed" do
  before{self.micon = Micon::Core.new}
  after{remove_constants :Tmp}

  it "scope" do
    class Tmp
      register_as :an_object
    end

    scope = micon.metadata[:an_object]
    initializer, dependencies = micon.metadata.initializers[:an_object]
    scope.should == :application
    initializer.call.should be_a(Tmp)
  end

  it "injection" do
    class Tmp
      inject object: :an_object

      class << self
        inject object: :an_object
      end
    end

    the_object = "An Object"
    micon.register(:an_object){the_object}

    Tmp.object.should == the_object
    Tmp.new.object.should == the_object
  end

  it "outjection" do
    class Tmp
      class << self
        inject object: :an_object
      end
    end

    the_object = "An Object"
    micon.register :an_object

    -> {Tmp.object}.should raise_error(/no initializer/)
    Tmp.object = the_object
    Tmp.object.should == the_object
  end

  it "empty?" do
    class Tmp
      register_as :an_object
    end

    micon.should be_empty
    micon[:an_object]
    micon.should_not be_empty
  end
end