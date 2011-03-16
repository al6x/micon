require 'spec_helper'

describe "Callbacks" do
  before do
    self.micon = Micon::Core.new
  end
  
  describe "components callbacs" do
    it "basic" do
      micon.register(:the_object){"The Object"}
    
      check = mock
      check.should_receive(:before)
      micon.before :the_object do
        check.before
      end
    
      check.should_receive(:after1).ordered
      check.should_receive(:after2).ordered
      obj = nil
      micon.after :the_object do |o|        
        check.after1
        obj = o
      end
      micon.after :the_object do |o|
        check.after2
        obj.object_id.should == o.object_id
      end
      
      micon[:the_object].should == obj
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
  
  describe "micelaneous" do
    it "should fire callbacks after assigning component" do
      micon.register(:the_object)
      check = mock
      check.should_receive(:done)
      micon.after :the_object do
        check.done
      end
      micon.the_object = 'the_object'
    end
    
    it "should raise error if callback defined after component already created" do
      micon.register(:the_object){"the_object"}
      micon[:the_object]
      
      -> {micon.before(:the_object){}}.should raise_error(/already created/)
      -> {micon.after(:the_object){}}.should raise_error(/already created/)
    end
    
    it "should raise error if callback defined after scope already started" do
      micon.activate :custom, {} do
        -> {micon.before_scope(:custom){}}.should raise_error(/already started/)
        -> {micon.after_scope(:custom){}}.should raise_error(/already started/)
      end
    end
    
    it ":after with bang: false should execute callback if component already started and also register it as :after callback" do
      micon.register(:the_object){"the_object"}
      micon[:the_object]
      
      check = mock
      check.should_receive(:first).twice      
      micon.after(:the_object, bang: false){check.first}
      
      micon.delete :the_object
      micon[:the_object]
    end
  end 
end