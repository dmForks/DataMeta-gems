## keep this underscore naming in the test subdir, it's easier to append files names to test
%w(stringio test/unit).each { |r| require r }
# this is expected to run from the project root, normally by the rake file

$VERBOSE = false # turn off noisy for the 1st release

require './lib/dataMetaPii'
require 'logger'
require 'dataMetaParse'

module DataMetaPiiTests

    L = Logger.new('piiTests.log', 0, 10_000_000)
    L.level = Logger::DEBUG
    L.datetime_format = '%Y-%m-%d %H:%M:%S'

# By the way, inspecting a parser does not make any difference compared to just to_s:
    L.info(%<Loaded base rules: #{DataMetaPii::BASE_RULES}

Loaded PII Commons Rules: #{DataMetaPii::PII_COMMONS.inspect}
Loaded Regstry Rules: #{DataMetaPii::REGISTRY}
Loaded AppLink Rules: #{DataMetaPii::APP_LINK}
>)
end
