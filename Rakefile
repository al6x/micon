require 'rake'
require 'fileutils'
current_dir = File.expand_path(File.dirname(__FILE__))
Dir.chdir current_dir


# 
# Specs
# 
require 'spec/rake/spectask'

task :default => :spec

Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_files = FileList["spec/**/*_spec.rb"].select{|f| f !~ /\/_/}
  t.libs = ["#{current_dir}/lib"]
end


# 
# Gem
# 
require 'rake/clean'
require 'rake/gempackagetask'

gem_options = {
  :name => "micon",
  :version => "0.1.2",
  :summary => "Assembles and manages pieces of your application",  
  :dependencies => %w()
}

gem_name = gem_options[:name]
spec = Gem::Specification.new do |s|
  gem_options.delete(:dependencies).each{|d| s.add_dependency d}
  gem_options.each{|k, v| s.send "#{k}=", v}
  
  s.name = gem_name
  s.author = "Alexey Petrushin"
  s.homepage = "http://github.com/alexeypetrushin/#{gem_options[:name]}"
  s.require_path = "lib"
  s.files = (%w{Rakefile readme.md} + Dir.glob("{lib,spec}/**/*"))
  
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true  
end

package_dir = "#{current_dir}/build"
Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true if RUBY_PLATFORM !~ /mswin/
  p.need_zip = true
  p.package_dir = package_dir
end

task :push do
  # dir = Dir.chdir package_dir do
  gem_file = Dir.glob("#{package_dir}/#{gem_name}*.gem").first
  system "gem push #{gem_file}"
  # end
end

task :clean do
  system "rm -r #{package_dir}"
end

task :release => [:gem, :push, :clean]