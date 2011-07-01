class Micon::Config    
  attr_reader :micon, :name
  def initialize micon, name
    @micon, @name = micon, name
  end
  
  def load        
    files = []
    files << find_file(config_path(name, nil), $LOAD_PATH)
    files << find_file(config_path(name, micon.mode_name), $LOAD_PATH) if micon.mode_name
    if micon.runtime_path
      files << find_file(runtime_config_path(name, nil), [micon.runtime_path])
      files << find_file(runtime_config_path(name, micon.mode_name), [micon.runtime_path]) if micon.mode_name
    end
    
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
    def config_path name, mode
      fs_name = name.to_s.gsub(/::/, '/')
      mode ? "/components/#{fs_name}.#{mode}.yml" : "/components/#{fs_name}.yml"
    end

    def runtime_config_path name, mode
      fs_name = name.to_s.gsub(/::/, '/')
      mode ? "/config/#{fs_name}.#{mode}.yml" : "/config/#{fs_name}.yml"
    end
  
    def find_file path, directories
      files = directories.collect{|dir| "#{dir}#{path}"}.select{|f| File.exist? f}
      raise "multiple configs for :#{name} component" if files.size > 1
      files.first
    end
end