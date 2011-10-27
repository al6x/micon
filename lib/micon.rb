require 'micon/support'

module Micon
  autoload :Metadata, 'micon/metadata'
  autoload :Config,   'micon/config'
  autoload :Core,     'micon/core'
  autoload :Metadata, 'micon/metadata'
end

# Initializing Micon.
micon = Micon::Core.new
micon.initialize!

def micon; ::MICON end unless $dont_create_micon_shortcut