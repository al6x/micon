require 'spec_helper'

describe "Initialization" do
  after do
    remove_constants :TheRouter
  end

  it "clone" do
    m = Micon::Core.new
    m.initialize!

    m.register(:the_value){'the_value'}
    m[:the_value]

    another = m.clone
    another.metadata.should include(:the_value)
    another.instance_variable_get('@registry').should include(:the_value)
    another.instance_variable_get('@application').should include(:the_value)
  end

  it "initialize! should set caller as global, deinitialize! should remove it" do
    m = Micon::Core.new
    m.initialize!

    ::MICON.object_id.should == m.object_id
    m.deinitialize!
    Object.const_defined?(:MICON).should be_false
  end

  it "should support isolation" do
    m1 = Micon::Core.new
    m1.initialize!

    m1.register(:first){'first'}
    m1.first.should == 'first'

    m1.deinitialize!

    # m2
    m2 = m1.clone
    m2.initialize!

    m2.first.should == 'first'
    m2.register(:second){'second'}
    m2.second.should == 'second'
    m2.deinitialize!

    # m1 shouldn't have any of m2 stuff
    m1.initialize!
    m1.first.should == 'first'
    m1.metadata.should_not include(:second)
    m1.include? :second
    m1.should_not include(:second)
  end

  # describe "constants" do
  #   it "deinitialize! should delete all defined constants" do
  #     m = Micon::Core.new
  #     m.initialize!
  #
  #     m.register(:TheRouter, constant: true){'TheRouter'}
  #     ::TheRouter.should == 'TheRouter'
  #
  #     m.deinitialize!
  #     Object.const_defined?(:TheRouter).should be_false
  #
  #     m.initialize!
  #     ::TheRouter.should == 'TheRouter'
  #   end
  # end
end