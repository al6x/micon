# Let's define some of our controllers, the PagesController, note - we
# don't register it as component.
class PagesController
  # We need access to :logger and :request, let's inject them
  inject :logger, :request

  def index
    # Here we can use injected component
    logger.info "Application: processing #{request}"
  end
end