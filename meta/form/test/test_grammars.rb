require './test/test_helper'

=begin rdoc
Test for the DataMetaForm grammars and parsing.

Assertions: http://ruby-doc.org/stdlib-1.9.3/libdoc/test/unit/rdoc/Test/Unit/Assertions.html
=end
class TestFmts < Test::Unit::TestCase

    include DataMetaFormTestUtil
    # loads the fmt grammar and creates the parser instance
    def setup
        DataMetaForm::Fmt.loadFormRules
    end

=begin rdoc
Test parsing
=end
    def test_parse
        model = DataMetaForm::Fmt.parse(IO.read('./test/test.dmForm'))
        bel = DataMetaForm::Fmt::Delim.new(7.chr)
        expected = [DataMetaForm::Fmt::Field.new('user_id', true)]
        expected << bel
        expected << DataMetaForm::Fmt::Field.new('first', true) << bel
        expected << DataMetaForm::Fmt::Field.new('mid', false) << bel
        expected << DataMetaForm::Fmt::Field.new('last', true) << bel
        expected << DataMetaForm::Fmt::Field.new('salary', true) << bel
        #noinspection RubyArgCount
        expected << DataMetaForm::Fmt::Field.new('created', true, 'yyyy-MM-dd HH:mm:ss') << bel
        expected << DataMetaForm::Fmt::Field.new('last_mod', false, 'yyyy-MM-dd HH:mm:ss') << bel
        expected << DataMetaForm::Fmt::Delim.new(10.chr)
        index = -1

        model.each { |item| # each fields list item
            index += 1
            msg = "Mismatch at index #{index}"
            xp = expected[index]
            case item
                when DataMetaForm::Fmt::Delim
                    raise "At [#{index}]: expected #{xp.class}, #{item.class}" unless xp.kind_of?(DataMetaForm::Fmt::Delim)
                    assert_equal(xp.val, item.val, msg)
                when DataMetaForm::Fmt::Field
                    raise "At [#{index}]: expected #{xp.class}, #{item.class}" unless xp.kind_of?(DataMetaForm::Fmt::Field)
                    assert_equal(xp.name, item.name, msg)
                    assert_equal(xp.isReq, item.isReq, msg)
                    assert_equal(xp.fmt, item.fmt, msg)
                else
                    # none of the interest
            end
        }
    end

end
