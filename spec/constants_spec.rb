# require 'spec_helper'
#
# describe "Autoloading" do
#   with_load_path "#{spec_dir}/get_constant_component/lib"
#
#   before do
#     self.micon = Micon::Core.new
#   end
#
#   after do
#     remove_constants :TheRouter, :TheRad, :TheController, :SomeModule
#   end
#
#   describe "get_constant_component" do
#     it "should autoload components" do
#       micon.get_constant_component(:TheController).should == "TheController"
#     end
#
#     it "should not raise error if component not defined" do
#       micon.get_constant_component(:TheValue).should == nil
#       micon.register(:TheValue, constant: true){"TheValue"}
#       micon.get_constant_component(:TheValue).should == "TheValue"
#     end
#
#     it "should get constants only" do
#       micon.register(:TheController){"TheController"}
#       micon.get_constant_component(:TheController).should == nil
#
#       micon.register(:TheController, constant: true){"TheController"}
#       micon.get_constant_component(:TheController).should == "TheController"
#     end
#   end
#
#   it 'validation' do
#     -> {micon.register 'TheController', constant: true}.should raise_error(/symbol/)
#     -> {micon.register 'TheController'.to_sym, constant: true, scope: :custom}.should raise_error(/scope/)
#   end
#
#   it "should use constants as components" do
#     -> {::TheRouter}.should raise_error(/uninitialized constant/)
#
#     micon.register :TheRouter, constant: true do
#       "TheRouter"
#     end
#
#     module ::TheRad
#       TheRouter.should == 'TheRouter'
#     end
#     ::TheRouter.should == 'TheRouter'
#     micon[:TheRouter].should == 'TheRouter'
#   end
#
#   it "should support nested constants" do
#     module ::TheRad; end
#     -> {::TheRad::TheView}.should raise_error(/uninitialized constant/)
#
#     micon.register 'TheRad::TheView'.to_sym, constant: true do
#       'TheRad::TheView'
#     end
#
#     module ::SomeModule
#       ::TheRad::TheView.should == 'TheRad::TheView'
#     end
#     ::TheRad::TheView.should == 'TheRad::TheView'
#     micon['TheRad::TheView'.to_sym].should == 'TheRad::TheView'
#   end
#
#   it "should check if constant is already defined" do
#     micon.register :TheRouter, constant: true do
#       class ::TheRouter; end
#       'TheRouter'
#     end
#     -> {::TheRouter}.should raise_error(/redefine/)
#   end
# end