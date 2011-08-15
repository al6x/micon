- remove threads and synchronization support, probably it will be never needed in any real situation, because
there's no multithreading in ruby.
- refactor specs, they are messy a little.
- maybe it makes sense to add ability to add dependencies for components after component registration?