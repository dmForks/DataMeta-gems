# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/utils'

# Unit test cases for the DataMetaParse
#  See for instance:
#  - test_full
# Assertions: http://ruby-doc.org/stdlib-1.9.3/libdoc/test/unit/rdoc/Test/Unit/Assertions.html
class TestNumberParse < Test::Unit::TestCase

    include DataMetaParseTestUtil
    L.info "Loaded Base Rules: #{BASE_RULS}"
    # Loads the grammars, creates a parser
    def setup
        numbers = Treetop.load('./test/numbers')
        L.info "Loaded numbers: #{numbers.inspect}"

        @parser = TestNumbersParser.new
        L.info "#{@parser.inspect}"
    end

=begin rdoc
Numbers parsing test
=end
    def test_numbers
        ast = DataMetaParse.parse(@parser,
                %q<1 123 4321 +4321 -4321 1.1 1.23 12.3 12. .12 +1.1 +1.23 +12.3 +12.  +.12 -1.1 -1.23 -12.3 -12. -.12>)
        raise 'Numbers parse unsuccessful' unless ast
        raise ast if ast.is_a?(DataMetaParse::Err)
        L.info "AST:\n#{ast.inspect}"
        assert_equal(1, ast.singleDecDigitNoSign.text_value.to_i)
        assert_equal(123, ast.mulDecDigitNoSign.text_value.to_i)
        assert_equal(4321, ast.signableIntNoSign.text_value.to_i)
        assert_equal(4321, ast.signableIntPlus.text_value.to_i)
        assert_equal(-4321, ast.signableIntMinus.text_value.to_i)
        assert_equal(1.1, ast.singleDigSingleDigFrac.text_value.to_f)
        assert_equal(1.23, ast.singDigDoubleDigFrac.text_value.to_f)
        assert_equal(12.3, ast.doubleDigSingleDigFrac.text_value.to_f)
        assert_equal(12.0, ast.doubleDigDotFrac.text_value.to_f)
        assert_equal(0.12, ast.dotDigitsFrac.text_value.to_f)
        assert_equal(1.1, ast.singleDigSingleDigFracPlus.text_value.to_f)
        assert_equal(1.23, ast.singDigDoubleDigFracPlus.text_value.to_f)
        assert_equal(12.3, ast.doubleDigSingleDigFracPlus.text_value.to_f)
        assert_equal(12.0, ast.doubleDigDotFracPlus.text_value.to_f)
        assert_equal(0.12, ast.dotDigitsFracPlus.text_value.to_f)
        assert_equal(-1.1, ast.singleDigSingleDigFracMinus.text_value.to_f)
        assert_equal(-1.23, ast.singDigDoubleDigFracMinus.text_value.to_f)
        assert_equal(-12.3, ast.doubleDigSingleDigFracMinus.text_value.to_f)
        assert_equal(-12.0, ast.doubleDigDotFracMinus.text_value.to_f)
        assert_equal(-0.12, ast.dotDigitsFracMinus.text_value.to_f)
    end

end
