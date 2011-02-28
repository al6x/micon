require 'spec_helper'

describe "Callbacks" do
  before :each do
    self.micon = MicroContainer.new
  end
  
  describe "components callbacs" do
    it "basic" do
      micon.register(:the_object){"The Object"}
    
      check = mock
      check.should_receive(:done)
      micon.before :the_object do
        check.done
      end
    
      micon.after :the_object do |o|
        o << " updated"
      end
      micon.after :the_object do |o|
        o << " even more updated"
      end
    
      micon[:the_object].should == "The Object updated even more updated"
    end
  
    it "should be able reference to the component itself inside of after filter (cycle reference)" do
      micon.register(:the_object){"The Object"}
      check = nil
      micon.after :the_object do
        check = micon[:the_object]
      end
      micon[:the_object]
      check.should == "The Object"
    end
  end
  
  describe "custom scope callbacks" do
    it "scope :before and :after callbacks" do
      check = mock
      check.should_receive(:before).with({}).ordered
      check.should_receive(:run).ordered
      check.should_receive(:after).with({}).ordered
      check.should_receive(:after2).with({}).ordered

      micon.before_scope(:custom){|container| check.before container}
      micon.after_scope(:custom){|container| check.after container}
      micon.after_scope(:custom){|container| check.after2 container}

      micon.activate(:custom, {}){check.run}
    end    
  end  
end