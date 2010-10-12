lib_dir = "#{__FILE__.parent_dirname}/lib"
$LOAD_PATH << lib_dir unless $LOAD_PATH.include? lib_dir

require "micon"