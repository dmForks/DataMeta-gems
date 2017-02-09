## keep this underscore naming in the test subdir, it's easier to append files names to test
%w(stringio test/unit logger).each { |r| require r }
# this is expected to run from the project root, normally by the rake file
require './lib/dataMetaParse'
require './lib/dataMetaParse/uriDataMeta'
require './test/utils'
