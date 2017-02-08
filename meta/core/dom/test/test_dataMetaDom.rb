# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/test_helper.rb'

# Unit test cases for the DataMetaDom
#  See for instance:
#  - test_full
class TestNewGem < Test::Unit::TestCase

    # an empty stub for now
    def setup
        DataMetaDom::L.level = Logger::DEBUG
    end

=begin rdoc
Tests splitting full name without namespace, the base class name only.
=end
    def test_splitNameSpaceClassOnly
        orig = 'ZeeKlass'
        ns, base = DataMetaDom.splitNameSpace('ZeeKlass')
        assert_nil(ns, "for the original #{orig}, namespace must be nil")
        assert_equal(orig, base)
    end

=begin rdoc
Helper method to test the given combination of the NS and the Base,
to vary the parameters and make sure they all work
=end
    def splitNameSpaceFullLevelN(origNs, origBase)
        origFull = DataMetaDom.combineNsBase(origNs, origBase)
        ns, base = DataMetaDom.splitNameSpace(origFull)
        assert_equal(origBase, base)
        assert_equal(origNs, ns)
        DataMetaDom::L.info "original: #{origNs}.#{origBase}, orig ver=#{origFull}, ns=#{ns}, base=#{base}"
    end

=begin rdoc
Uses splitNameSpaceFullLevelN to test 3 levels of namespace nesting.
=end
    def test_splitNameSpaceFull
        %w(Klass ZeeKlass).each { |c|
            splitNameSpaceFullLevelN('one', c)
            splitNameSpaceFullLevelN('one.two', c)
            splitNameSpaceFullLevelN('one.two.three', c)
        }
    end

    # Semantic Version Parsing scenarios
    def test_semVerParsing
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('.2.3') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('1.2.') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('1a.2.3') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('1.2a.3') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('1.2.a3') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new(nil) }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('-1.2.3') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('1.-2.3') }
        assert_raise(ArgumentError) { DataMetaDom::SemVer.new('1.2.-3') }

        assert_true(DataMetaDom::SemVer.new('12.234.456').toVarName == '12_234_456')
        assert_true(DataMetaDom::SemVer.new('12.234.456.7890').toVarName == '12_234_456_7890')
        assert_true(DataMetaDom::SemVer.new('12.234.456.7890.blah.yada.meh').toVarName == '12_234_456_7890')
        
        v = DataMetaDom::SemVer.new('12.345.6.7')
        DataMetaDom::L.debug("Parsed: #{fullSemVerInfo(v)}")
        assertSemVer(v, 12, 345, 6, 7)

        v = DataMetaDom::SemVer.new('12.345.6.7.blah-blah-yada.yada')
        DataMetaDom::L.debug("Parsed: #{fullSemVerInfo(v)}")
        assertSemVer(v, 12, 345, 6, 7)

        v = DataMetaDom::SemVer.new('12.345.6')
        DataMetaDom::L.debug("Parsed: #{fullSemVerInfo(v)}")
        assertSemVer(v, 12, 345, 6, nil)

        v = DataMetaDom::SemVer.new('12.345.6.blah-blah-yada.yada')
        DataMetaDom::L.debug("Parsed: #{fullSemVerInfo(v)}")
        assertSemVer(v, 12, 345, 6, nil)

    end

    # Semantic Version Comparison
    def test_semVerCmp
        v1, v2 = DataMetaDom::SemVer.new('5.6.7'), DataMetaDom::SemVer.new('12.15.16')
        assert_true( (v1.source <=> v2.source) > 0) # stringwise, v1 > v2
        assert_true( (v1 <=> v2) < 0) # versionwise, v1 < v2

        v1, v2 = DataMetaDom::SemVer.new('5.6.7.8'), DataMetaDom::SemVer.new('5.6.7')
        assert_true( (v1.source <=> v2.source) > 0)
        DataMetaDom::L.debug("v1.items=#{v1.items.inspect}, v2.items=#{v2.items.inspect}")
        assert_true( (v1 <=> v2) > 0)

        v1, v2 = DataMetaDom::SemVer.new('5.6.7'), DataMetaDom::SemVer.new('5.6.7.8')
        assert_true( (v1.source <=> v2.source) < 0)
        assert_true( (v1 <=> v2) < 0)

        v1, v2 = DataMetaDom::SemVer.new('5.6.7.3'), DataMetaDom::SemVer.new('5.6.7.12')
        assert_true( (v1.source <=> v2.source) > 0)
        assert_true( (v1 <=> v2) < 0)

        v1, v2 = DataMetaDom::SemVer.new('5.6.7.8'), DataMetaDom::SemVer.new('5.6.7.8')
        assert_true( (v1.source <=> v2.source) == 0)
        assert_true( (v1 <=> v2) == 0)
    end

    def test_diffLevel
        assert_equal(DataMetaDom::SemVer.new('1.2.3').diffLevel(DataMetaDom::SemVer.new('1.2.3.blah')), DataMetaDom::SemVer::DiffLevel::NONE)
        assert_equal(DataMetaDom::SemVer.new('1.2.3.4').diffLevel(DataMetaDom::SemVer.new('1.2.3.4.blah')), DataMetaDom::SemVer::DiffLevel::NONE)
        assert_equal(DataMetaDom::SemVer.new('1.2.3').diffLevel(DataMetaDom::SemVer.new('2.2.3.blah')), DataMetaDom::SemVer::DiffLevel::MAJOR)
        assert_equal(DataMetaDom::SemVer.new('1.2.3').diffLevel(DataMetaDom::SemVer.new('1.4.3.blah')), DataMetaDom::SemVer::DiffLevel::MINOR)
        assert_equal(DataMetaDom::SemVer.new('1.2.3').diffLevel(DataMetaDom::SemVer.new('1.2.4.blah')), DataMetaDom::SemVer::DiffLevel::UPDATE)
        assert_equal(DataMetaDom::SemVer.new('1.2.3.4').diffLevel(DataMetaDom::SemVer.new('1.2.3.blah')), DataMetaDom::SemVer::DiffLevel::BUILD)
        assert_equal(DataMetaDom::SemVer.new('1.2.3').diffLevel(DataMetaDom::SemVer.new('1.2.3.4.blah')), DataMetaDom::SemVer::DiffLevel::BUILD)
        assert_equal(DataMetaDom::SemVer.new('1.2.3.4').diffLevel(DataMetaDom::SemVer.new('1.2.3.5.blah')), DataMetaDom::SemVer::DiffLevel::BUILD)
    end

    # Helper method
    def fullSemVerInfo(semVer)
       %<#{semVer.to_long_s}: maj=#{semVer.major}, min=#{semVer.minor}, upd=#{semVer.update}, bld=#{semVer.build}>
    end

    # Helper method
    def assertSemVer(semVer, maj, min, upd, bld)
        assert_equal(semVer.major, maj)
        assert_equal(semVer.minor, min)
        assert_equal(semVer.update, upd)
        assert_equal(semVer.build, bld)
    end
end

