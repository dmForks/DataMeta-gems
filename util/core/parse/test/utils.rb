
=begin rdoc
Utilities for testing
=end
module DataMetaParseTestUtil
    L = Logger.new('parseTests.log', 0, 10000)
    L.level = Logger::DEBUG
    L.datetime_format = '%Y-%m-%d %H:%M:%S'
    # same as: DataMetaParse.loadBaseRulz
    BASE_RULS = Treetop.load('./lib/dataMetaParse/basic')

end
