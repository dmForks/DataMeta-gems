# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/test_helper.rb'

=begin rdoc
Unit test cases for the DataMetaPii
=end
class TestNewGem < Test::Unit::TestCase
    include DataMetaPiiTests

    # an empty stub for now
    def setup;
        @impactConstVals = DataMetaPii::Impact.constants.map{|c| ":#{DataMetaPii::Impact.const_get(c)}"}
    end

=begin rdoc
Test obtaining a constant list from a module
=end
    def test_constantList
        v = DataMetaPii::RegKeyVo.new('A_PII_field',
                                  {DataMetaPii::RegKeyVo::LEVEL => DataMetaPii::Impact::CONFIDENTIAL, "foo" => "bar", "val" => 123.456})

        L.info(%<Impact constants: #{DataMetaPii::Impact.constants.map{|c| "#{c}=#{DataMetaPii::Impact.const_get(c)}"}.join('; ')}
first PII VO created: #{v.to_tree_image(DataMetaPii::INDENT)}
>)
        xcp = assert_raise(ArgumentError) { DataMetaPii::RegKeyVo.new('A_PII_field', {DataMetaPii::RegKeyVo::LEVEL => ''}) }
        assert(xcp.message.start_with?('Impact level missing or empty in'))

        xcp = assert_raise(ArgumentError) { DataMetaPii::RegKeyVo.new('A_PII_field', {'foo' => 'bar'}) }
        assert(xcp.message.start_with?('Impact level missing or empty in'))

        xcp = assert_raise(ArgumentError) { DataMetaPii::RegKeyVo.new('A PII field',
                                                                  {DataMetaPii::RegKeyVo::LEVEL => DataMetaPii::Impact::CONFIDENTIAL}) }

        assert(xcp.message.start_with?('Invalid PII key: '))

        xcp = assert_raise(ArgumentError) { DataMetaPii::RegKeyVo.new('A_PII_field',
                                                                  {DataMetaPii::RegKeyVo::LEVEL => :bad_impact_level}) }

        L.info(%<Testing #{:bad_impact_level}: #{xcp.message}\n#{xcp.backtrace.join("\n\t")}\n>)
        assert(xcp.message.start_with?('Unsupported Impact Level '))
    end
end
