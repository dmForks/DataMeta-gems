## keep this underscore naming in the test subdir, it's easier to append files names to test

require 'test/unit'
require 'dataMetaDom'
require 'fileutils'

# this is expected to run from the project root, normally by the rake file
require './lib/dataMetaAvro'
