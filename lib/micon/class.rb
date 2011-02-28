class Class
  # register_as :session, scope: :request
  # register_as :loggger
  def register_as *args
    ::MICON.register(*args){self.new}
  end
end