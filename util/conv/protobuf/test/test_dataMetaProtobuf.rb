# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/test_helper.rb'
require 'google/protobuf'
require 'open3'

# Unit test cases for the DataMetaProtobuf
#  See for instance:
#  - test_full
class TestNewGem < Test::Unit::TestCase
    H1 ||= '*' * 15

    L = Logger.new('dataMetaProtobufTests.log', 0, 10_000_000)
    L.level = Logger::DEBUG
    L.datetime_format = '%Y-%m-%d %H:%M:%S'

    MODEL_BASE = 'sample'
    GEN_TARGET = '.tmp'
    PROTO_SRC = File.join(GEN_TARGET, "#{MODEL_BASE}.proto")

    # an empty stub for now
    def setup; end

    # Smell-check the parsing
    def test_parsing
        model = DataMetaDom::Model.new
        model.parse(File.join(File.dirname(__FILE__), 'sample.dmDom'), options={autoVerNs: true})
        L.info(%<Model: #{model}>)
        FileUtils.rmtree(GEN_TARGET) if File.exist?(GEN_TARGET)
        FileUtils.mkpath GEN_TARGET
        IO.write(PROTO_SRC, DataMetaProtobuf.genSchema(model), mode: 'wb')
        cmd = "protoc --ruby_out=. #{PROTO_SRC}" # as counterintuitive it is, but . means actually the dir where the source is found
        L.info(%<Running "#{cmd}">)
        o,e,s= Open3.capture3(cmd, :binmode => true)
        unless s.to_i == 0
            $stderr.puts %|#{H1} OUT #{H1}
#{o}
#{H1} ERR #{H1}
#{e}
#{H1} state=#{s.inspect}
|
            raise RuntimeError, %|ERRORS running "#{cmd}"|
        end

        L.info("Verifying schema #{PROTO_SRC}")
        require "./#{GEN_TARGET}/#{MODEL_BASE}_pb"
        # see if I can use those messages and the enum
        optionals = Org::Ebay::Datameta::Examples::Conv::Protobuf::Optionals.new
        allTypes = Org::Ebay::Datameta::Examples::Conv::Protobuf::AllTypes.new
        red = Org::Ebay::Datameta::Examples::Conv::Protobuf::BaseColor::Red
        blue = Org::Ebay::Datameta::Examples::Conv::Protobuf::BaseColor::Blue
        L.info("Red = #{red}; Blue = #{blue}")
    end
end
