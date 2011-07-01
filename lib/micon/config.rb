class Micon::Config    
  attr_reader :micon, :name
  def initialize micon, name
    @micon, @name = micon, name
  end
  
  def load        
    files = []
    files.push *config_paths.collect{|path| find_file(path, $LOAD_PATH)}
    files.push *runtime_config_paths.collect{|path| find_file(path, [micon.runtime_path])} if micon.runtime_path?

    config = {}
    files.compact.each do |f|
      c = YAML.load_file(f)
      next unless c
      raise "component config must be a Hash (#{f})!" unless c.is_a? Hash
      c.each{|k, v| config[:"#{k}="] = v}
    end

    config.empty? ? nil : config
  end
  
  protected
    def config_paths
      fs_name = name.to_s.gsub(/::/, '/')
      paths = ["/components/#{fs_name}.yml"]
      paths << "/components/#{fs_name}.#{micon.mode}.yml" if micon.mode?
      paths
    end

    def runtime_config_paths
      fs_name = name.to_s.gsub(/::/, '/')
      paths = ["/config/#{fs_name}.yml"]
      if micon.mode?
        paths << "/config/#{fs_name}.#{micon.mode}.yml"
        paths << "/config/#{micon.mode}/#{fs_name}.yml"
      end
      paths
    end
  
    def find_file path, directories
      files = directories.collect{|dir| "#{dir}#{path}"}.select{|f| File.exist? f}
      raise "multiple configs for :#{name} component" if files.size > 1
      files.first
    end
end