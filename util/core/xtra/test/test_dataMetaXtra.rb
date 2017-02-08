# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/test_helper.rb'
require 'date'

# Unit test cases for the DataMetaXtra
# Assertions: http://ruby-doc.org/stdlib-1.9.3/libdoc/test/unit/rdoc/Test/Unit/Assertions.html
class TestNewGem < Test::Unit::TestCase

    # an empty stub for now
    def setup; end

    # Tests DataMetaXtra::Str.camelize.
    def test_Camelize
        original = 'this_one_var'
        assert_equal('ThisOneVar', DataMetaXtra::Str.camelize(original))
        original = 'That_oThEr_vAR'
        assert_equal('ThatOtherVar', DataMetaXtra::Str.camelize(original))
    end

    # Tests DataMetaXtra::Str.
    def test_downCaseFirst
        original = 'That_oTHer_vAr'
        assert_equal('that_oTHer_vAr', DataMetaXtra::Str.downCaseFirst(original))
    end

    # Tests DataMetaXtra::Str.
    def test_Variablize
        original = 'That_oTHer_vAr'
        assert_equal('thatOtherVar', DataMetaXtra::Str.variablize(original))
    end

    # Tests DataMetaXtra::Str.firstCap.
    def test_firstCap
        original = 'thisOneVar'
        assert_equal('ThisOneVar', DataMetaXtra::Str.capFirst(original))
    end

    # Tests DataMetaXtra.defaultLogger so it does not throw an exception and works.
    def test_getLogger
        DataMetaXtra.defaultLogger.warn('Here is a harmless warning from the default logger')
    end

    # Tests if the require on the top takes effect in the new block.
    # If not, this test will fail.
    def test_bindingReqs
        newBlock = DataMetaXtra.nilBinding
        puts "bindingReqs: #{eval('Date.today.next_day', newBlock)}"
    end

=begin rdoc
Test the Perm object creation from a string.
=end
    def testPermsFromStr
        assert_equal(DataMetaXtra::FileSys::Perm.new(false, false, false), DataMetaXtra::FileSys::Perm.of(''))  # 000
        assert_equal(DataMetaXtra::FileSys::Perm.new(false, false, true), DataMetaXtra::FileSys::Perm.of('x'))  # 001
        assert_equal(DataMetaXtra::FileSys::Perm.new(false, true, false), DataMetaXtra::FileSys::Perm.of('w')) # 010
        assert_equal(DataMetaXtra::FileSys::Perm.new(false, true, true), DataMetaXtra::FileSys::Perm.of('wx')) # 011
        assert_equal(DataMetaXtra::FileSys::Perm.new(false, true, true), DataMetaXtra::FileSys::Perm.of('xw'))
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, false, false), DataMetaXtra::FileSys::Perm.of('r')) # 100
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, false, true), DataMetaXtra::FileSys::Perm.of('xr')) # 101
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, false, true), DataMetaXtra::FileSys::Perm.of('rx'))
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, false), DataMetaXtra::FileSys::Perm.of('wr')) # 110
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, false), DataMetaXtra::FileSys::Perm.of('rw'))
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, true), DataMetaXtra::FileSys::Perm.of('rwx')) # 111
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, true), DataMetaXtra::FileSys::Perm.of('xrwx'))
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, true), DataMetaXtra::FileSys::Perm.of('xrw'))
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, true), DataMetaXtra::FileSys::Perm.of('wxr'))
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, true), DataMetaXtra::FileSys::Perm.of('xwr'))
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of('a') }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of('ax') }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of('ar') }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of('ra') }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of('war') }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of(Date.new) }
    end

=begin rdoc
Test the Perm object creation from a Fixnum.
=end
    def testPermsFromNum
        xm = DataMetaXtra::FileSys::Perm::EXEC_MASK
        rm = DataMetaXtra::FileSys::Perm::READ_MASK
        wm = DataMetaXtra::FileSys::Perm::WRITE_MASK

        assert_equal(DataMetaXtra::FileSys::Perm.new(false, false, false), DataMetaXtra::FileSys::Perm.of(0))  # 000

        assert_equal(DataMetaXtra::FileSys::Perm.new(false, false, true), DataMetaXtra::FileSys::Perm.of(xm))  # 001

        assert_equal(DataMetaXtra::FileSys::Perm.new(false, true, false),
                             DataMetaXtra::FileSys::Perm.of(wm)) # 010
        assert_equal(DataMetaXtra::FileSys::Perm.new(false, true, true), DataMetaXtra::FileSys::Perm.of(wm | xm)) # 011
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, false, false), DataMetaXtra::FileSys::Perm.of(rm)) # 100
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, false, true), DataMetaXtra::FileSys::Perm.of(rm | xm)) # 101
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, false), DataMetaXtra::FileSys::Perm.of(rm | wm)) # 110
        assert_equal(DataMetaXtra::FileSys::Perm.new(true, true, true), DataMetaXtra::FileSys::Perm.of(rm | wm | xm)) # 111
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of(-1) }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::Perm.of(8) }
    end

    def testPosixPerms
        assert_equal(DataMetaXtra::FileSys::PosixPerms.new(DataMetaXtra::FileSys::Perm::ALL, nil, nil),
                     DataMetaXtra::FileSys::PosixPerms.new('rwx', nil, nil, nil))

        assert_equal(DataMetaXtra::FileSys::PosixPerms.new(DataMetaXtra::FileSys::Perm::NONE, nil, nil),
                     DataMetaXtra::FileSys::PosixPerms.new('', nil, nil, nil))

        assert_equal(DataMetaXtra::FileSys::PosixPerms.new(DataMetaXtra::FileSys::Perm.of('rx'),
                                                       DataMetaXtra::FileSys::Perm.of('wx'),
                                                       DataMetaXtra::FileSys::Perm.of('rw'),
                                                       DataMetaXtra::FileSys::Perm.of('rwx')),
                     DataMetaXtra::FileSys::PosixPerms.new('xr', 'xw', 'wr', 'wrx'))

        xm = DataMetaXtra::FileSys::Perm::EXEC_MASK
        rm = DataMetaXtra::FileSys::Perm::READ_MASK
        wm = DataMetaXtra::FileSys::Perm::WRITE_MASK

        assert_equal(DataMetaXtra::FileSys::PosixPerms.new(DataMetaXtra::FileSys::Perm.of('rx'),
                                                       DataMetaXtra::FileSys::Perm.of('wx'),
                                                       DataMetaXtra::FileSys::Perm.of('rw'),
                                                       DataMetaXtra::FileSys::Perm.of('rwx')),
                     DataMetaXtra::FileSys::PosixPerms.new(rm | xm, wm | xm, rm | wm, rm | wm |xm ))
        assert_equal(0536, DataMetaXtra::FileSys::PosixPerms.new(DataMetaXtra::FileSys::Perm.of('rx'),
                                                               DataMetaXtra::FileSys::Perm.of('wx'),
                                                               DataMetaXtra::FileSys::Perm.of('rw')).to_i)
    end

    def testPosixOwns
        theUser = DataMetaXtra::FileSys::IdName.new(nil, 'theUser')
        theGroup = DataMetaXtra::FileSys::IdName.new(nil, 'theGroup')
        assert_equal(DataMetaXtra::FileSys::IdName.new(nil, 'theUser'), DataMetaXtra::FileSys::IdName.forName('theUser'))
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::IdName.new(nil, 'the User') }
        assert_raise(ArgumentError) { DataMetaXtra::FileSys::IdName.forName('the User') }
        owns = DataMetaXtra::FileSys::PosixOwn.new('theUser', 'theGroup')
        assert_equal(theUser, owns.u)
        assert_equal(theGroup, owns.g)
    end
end
