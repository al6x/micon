# the :logger is one per application, it's a static component (like singleton)
class Logger
  register_as :logger
  attr_accessor :log_file_path
  def info msg
    puts "#{msg} (writen to #{log_file_path})" unless defined?(RSpec)
  end
end