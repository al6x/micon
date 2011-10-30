**Documentation:** http://alexeypetrushin.github.com/micon

Silent killer of dependencies and configs

Micon allows You easilly and transparently eliminate dependencies and configs. Usually, when You are building complex system following tasks should be solved:

- where the component's code is located.
- in what order should it be loaded.
- what configs does the component needs to be properly initialized.
- where those configs are stored.
- how to change configs in different environments.
- where are dependencies for component and how they should be initialized.
- how to replace some components with custom implementation.
- how to assembly parts of application for specs/tests.
- how to restore state after each spec/test (isolate it from each other).
- how to control life-cycle of dynamically created components.
- connecting components to assemble an application.

*By component I mean any parts of code logically grouped together.*

Micon **solves all these tasks automatically**, and has the following **price** - You has to:

- use the `register(component_name, &initialization_block)` method for component initialization.
- use the `inject(component_name)` to whire components toghether.
- place component definitions in the `lib/components` folder.

That's all the price, not a big one, compared to the value, eh? It's all You need to know about it to use 95% of it, there are also 2-3 more specific methods, but they are needed very rarelly.

Techincally Micon is sort of Dependency Injector, but because of its simplicity and invisibility it looks like an alien compared to its complex and bloated IoC / DI cousins.

Install Micon with Rubygems:

    gem install micon

Once installed, You can proceed with the examples below.

The project hosted on [GitHub][project]. You can report bugs and discuss features on the [issues page][issues].

### Basic example

``` ruby
require 'micon'
require 'logger'

# Registering `:logger` component.
micon.register(:logger){Logger.new STDOUT}

class Application
  # Whiring the `:logger` component and application together.
  inject :logger

  # Now You can use `:logger` as if it's an usual class member.
  def run
    logger.info 'running ...'
  end
end

# Running our application, type:
#
#     ruby docs/basics.rb
#
# And You should see in the console something like this:
#
#     [2011-08-16T19:09:05.921238 #24944]  INFO -- : running ...
#
Application.new.run
```

### Advanced example

It's hard to see advantages of Dependency Injection using trivial example, so this example is
more complicated.

Let's pretend that we are building the Ultimate Web Framework, RoR Killer. There will be lot's
of modules and dependencies, let's see how Micon can eliminate them.

We build our framework in two steps:

- the first version [ultima1.rb][ultima1] build **without Micon**.
- second version [ultima2.rb][ultima2] refactored **using Micon**.

You can compare these two examples and see advantages of using Dependency Injection.

If You are interested in more samples, please take a look at the [Rad SBS][rad_sbs] it's build using Micon.

[ultima1]: http://alexeypetrushin.github.com/micon/ultima1.html
[ultima2]: http://alexeypetrushin.github.com/micon/ultima3.html

[project]: https://github.com/alexeypetrushin/micon
[issues]:  https://github.com/alexeypetrushin/micon/issues
[rad_sbs]: http://sbs.4ire.net