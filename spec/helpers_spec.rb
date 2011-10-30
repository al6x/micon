require 'spec_helper'

describe "Helpers" do
  before{self.micon = Micon::Core.new}
  after{remove_constants :Tmp}

  it "register_as" do
    class Tmp
      micon.should_receive :register do |name, &initializer|
        name.should == :an_object
        initializer.call.class.should == Tmp
      end

      register_as :an_object
    end
  end

  it "inject" do
    class Tmp
      inject :an_object
    end
    tmp = Tmp.new

    micon.should_receive(:[]).with :an_object
    tmp.an_object

    micon.should_receive(:[]=).with :an_object, 'An Object'
    tmp.an_object = 'An Object'

    micon.should_receive(:include?).with :an_object
    tmp.an_object?

    # Another form.
    class Tmp
      inject other: :other_object
    end
    micon.should_receive(:[]).with :other_object
    tmp.other
  end
end