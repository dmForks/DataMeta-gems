## keep this underscore naming in the test subdir, it's easier to append files names to test
%w(stringio test/unit).each { |r| require r }
# this is expected to run from the project root, normally by the rake file
require './lib/dataMetaForm'
require './lib/dataMetaForm/ptf'
require 'dataMetaParse'
require 'logger'

module DataMetaFormTestUtil

    L = Logger.new('parseTests.log', 0, 10000)
    L.level = Logger::DEBUG
    L.datetime_format = '%Y-%m-%d %H:%M:%S'
    BASE_RULES = DataMetaParse.loadBaseRulz
    L.info("Loaded base rules: #{BASE_RULES.inspect}")
end
