# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/test_helper.rb'
require 'avro'

# Unit test cases for the DataMetaAvro
#  See for instance:
#  - test_full
class TestNewGem < Test::Unit::TestCase

    L = Logger.new('dataMetaAvroTests.log', 0, 10_000_000)
    L.level = Logger::DEBUG
    L.datetime_format = '%Y-%m-%d %H:%M:%S'

    GEN_TARGET = '.tmp'

    # an empty stub for now
    def setup; end

    # Smell-check the parsing
    def test_parsing
        model = DataMetaDom::Model.new
        model.parse(File.join(File.dirname(__FILE__), 'sample.dmDom'), options={autoVerNs: true})
        L.info(%<Model: #{model}>)
        FileUtils.rmtree(GEN_TARGET) if File.exist?(GEN_TARGET)
        FileUtils.mkpath GEN_TARGET
        DataMetaAvro.genSchema(model, GEN_TARGET)
        Dir.entries(GEN_TARGET).select{|e| e.end_with?('.avsc')}.each{ |e|
            L.info("Verifying schema #{e}")
            schema = IO.read(File.join(GEN_TARGET, e))
            projection = Avro::Schema.parse(schema) # if schema is invalid, this will cause an error
            L.info(projection.inspect)
        }
    end
end
