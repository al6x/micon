# The :controller component should be created and destroyed dynamically, 
# for each request, we specifying that component is dynamic 
# by declaring it's :scope. 
# And, we don't know beforehead what it actully will be, for different 
# request there can be different controllers, 
# so, here we just declaring it without any initialization block, it
# will be created at runtime later.
rad.register :controller, scope: :request