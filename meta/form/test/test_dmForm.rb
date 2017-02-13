# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/test_helper.rb'

# Unit test cases for the DataMetaForm
#  See for instance:
#  - test_full
class TestFlows < Test::Unit::TestCase

    # an empty stub for now
    def setup;
    end

    def test_badFormats
        assert_raise(ArgumentError) { DataMetaForm::Fmt::Delim.new('')  } # empty delimiter not supported
        # Multi-symbol delimiters not supported
        assert_raise(RuntimeError) { DataMetaForm::Fmt::Delim.new(', ').toDataMetaForm  }
        # Not supported delimiter code
        assert_raise(RuntimeError) { DataMetaForm::Fmt::Delim.new(',').toDataMetaForm }
        assert_raise(ArgumentError) { DataMetaForm::Fmt::Model.new << 1 } # not a FmtItem
    end

=begin rdoc
Tests exporting the Format model to the source
=end
    def test_fmtToDataMetaForm
        tab = DataMetaForm::Fmt::Delim.new("\t")
        bel = DataMetaForm::Fmt::Delim.new(7.chr)
        lf = DataMetaForm::Fmt::Delim.new(10.chr)
        expected = <<DATAMETAFORM_SOURCE
/*
  Backspace codes specified as standard ASCII:
  http://www.december.com/html/spec/ascii.html

  There may be extra codes introduced later
*/
record
    \\HT    \\BEL    +fieldName
    \\BEL    -otherField|some format|
    \\NL
end
DATAMETAFORM_SOURCE
        
        model = DataMetaForm::Fmt::Model.new
        model << tab << bel
        model << DataMetaForm::Fmt::Field.new('fieldName', true)
        model << bel
        model << DataMetaForm::Fmt::Field.new('otherField', false, 'some format')
        model << lf

        assert_equal(expected, model.toDataMetaForm)
    end

=begin rdoc
Test conversions of the DataMetaForm/Java formats into Ruby formats
=end
    def test_dttmConversions
        assert_equal('%Y-%m-%d %H:%M:%S', DataMetaForm::Dttm.toRubyFmt('yyyy-MM-dd HH:mm:ss'))
        assert_equal('%Y-%m-%d %H%M%S', DataMetaForm::Dttm.toRubyFmt('yyyy-MM-dd HHmmss'))
        assert_equal('%Y%m%d %H%M%S', DataMetaForm::Dttm.toRubyFmt('yyyyMMdd HHmmss'))
        assert_equal('%Y%m%d%H%M%S', DataMetaForm::Dttm.toRubyFmt('yyyyMMddHHmmss'))
        assert_equal('=%Y-%m-%d %H:%M:%S', DataMetaForm::Dttm.toRubyFmt('=yyyy-MM-dd HH:mm:ss'))
        assert_equal('%Y-%m-%d %H:%M:%S=', DataMetaForm::Dttm.toRubyFmt('yyyy-MM-dd HH:mm:ss='))
        assert_equal('=%Y-%m-%d %H:%M:%S=', DataMetaForm::Dttm.toRubyFmt('=yyyy-MM-dd HH:mm:ss='))
        assert_equal('=%Y-%m-%d -=- %H:%M:%S=', DataMetaForm::Dttm.toRubyFmt('=yyyy-MM-dd -=- HH:mm:ss='))
        assert_equal('%Y-%m-%d', DataMetaForm::Dttm.toRubyFmt('yyyy-MM-dd'))
        assert_equal('%H:%M:%S', DataMetaForm::Dttm.toRubyFmt('HH:mm:ss'))
    end

end
