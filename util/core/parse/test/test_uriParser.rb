# keep this underscore naming in the test subdir, it's easier to append files names to test
require './test/utils'

# Unit test cases for the DataMetaParse
#  See for instance:
#  - test_full
# Assertions: https://ruby-doc.org/stdlib-2.1.4/libdoc/test/unit/rdoc/Test/Unit/Assertions.html
#noinspection RubyStringKeysInHashInspection
class TestDataMetaParse < Test::Unit::TestCase

    include DataMetaParseTestUtil

    # Stub
    def setup
        DataMetaParse::Uri.loadRulz
    end

=begin rdoc
Checks one URI specification, reports results
=end
    def assertUri(uriSpec, expected)
        uri = DataMetaParse::Uri.parse(uriSpec)
        if uri
            L.info %Q<parsed "#{uriSpec}"; protocol: #{uri.proto}, user: #{uri.user}, pwd=#{uri.pwd}, host:#{uri.host}> +
                   ", port=#{uri.port}, path:#{uri.path}, props: #{uri.props.inspect}\nre:#{uri}"
        else
            L.info %Q<parsed "#{uriSpec}", no match>
        end

        assert_equal(expected, uri) # assert_equal goes by object.eql?
    end

    # Tests General URI grammar
    def test_GeneralUriGrammar
#proto, user, pwd, host, port, path, props
        assertUri(%q<http://www.domain.tld>, DataMetaParse::Uri.new('http', nil, nil, 'www.domain.tld', nil, nil, {}))
        assertUri(%q<http://www.domain.tld/>, DataMetaParse::Uri.new('http', nil, nil, 'www.domain.tld', nil, nil, {}))

        assertUri(%q<http://www.domain.tld:9090>,
                  DataMetaParse::Uri.new('http', nil, nil, 'www.domain.tld', 9090, nil, {}))

        assertUri(%q<http://www.domain.tld:9090/>,
                  DataMetaParse::Uri.new('http', nil, nil, 'www.domain.tld', 9090, nil, {}))

        assertUri(%q<http://joe_1@www.domain.tld>,
                  DataMetaParse::Uri.new('http', 'joe_1', nil, 'www.domain.tld', nil, nil, {}))

        assertUri(%q<https://joe_1@www.domain.tld>,
                  DataMetaParse::Uri.new('https', 'joe_1', nil, 'www.domain.tld', nil, nil, {}))

        assertUri(%q<http://joe_1:secret@www.domain.tld>,
                  DataMetaParse::Uri.new('http', 'joe_1', 'secret', 'www.domain.tld', nil, nil, {}))

        assertUri(%q<https://joe_1:secr%26et@www.domain.tld>,
                  DataMetaParse::Uri.new('https', 'joe_1', 'secr&et', 'www.domain.tld', nil, nil, {}))

        assertUri(%q<ftp://www.domain.tld/path/dir>,
                  DataMetaParse::Uri.new('ftp', nil, nil, 'www.domain.tld', nil, 'path/dir', {}))

        assertUri(%q<http://www.domain.tld/path/dir>,
                  DataMetaParse::Uri.new('http', nil, nil, 'www.domain.tld', nil, 'path/dir', {}))

        assertUri(%q<http://www.domain.tld/path/dir?qa=aVal&qb=bVal>,
                  DataMetaParse::Uri.new('http', nil, nil, 'www.domain.tld', nil, 'path/dir',
                                       {'qa' => 'aVal', 'qb' => 'bVal'}))

        assertUri(%q<http://joe:secret@www.domain.tld/path/dir?qa=aVal&qb&qc=cVal>,
                  DataMetaParse::Uri.new('http', 'joe', 'secret', 'www.domain.tld', nil, 'path/dir',
                                       {'qa' => 'aVal', 'qb' => nil, 'qc' => 'cVal'}))

        assertUri(%q<http://joe:secret@www.domain.tld/path/dir?qa=a%2FVal&qb=b%26Val&qc>,
                  DataMetaParse::Uri.new('http', 'joe', 'secret', 'www.domain.tld', nil, 'path/dir',
                                       {'qa' => 'a/Val', 'qb' => 'b&Val', 'qc' => nil}))

        assertUri(%q<http://joe:secret@www.domain.tld:8443/path/dir?qa=a%2FVal&qb=b%26Val&qc>,
                  DataMetaParse::Uri.new('http', 'joe', 'secret', 'www.domain.tld', 8443, 'path/dir',
                                       {'qa' => 'a/Val', 'qb' => 'b&Val', 'qc' => nil}))

        assertUri(%q<file:///dir/otherDir/file.ext>,
                  DataMetaParse::Uri.new('file', nil, nil, nil, nil, '/dir/otherDir/file.ext', {}))

        assertUri(%q<file://dir/otherDir/file.ext>,
                  DataMetaParse::Uri.new('file', nil, nil, nil, nil, 'dir/otherDir/file.ext', {}))

        assertUri(%q<hdfs://node-geo-ss.vip.acme.com/dir/otherDir/file.ext?cluster=hadoopCluster&format=seqFile&blkSize=128M>,
                  DataMetaParse::Uri.new('hdfs', nil, nil, 'node-geo-ss.vip.acme.com', nil, 'dir/otherDir/file.ext',
                                       {'cluster' => 'hadoopCluster', 'format' => 'seqFile', 'blkSize' => '128M'}))

        assertUri(%q<hdfs://node-geo-ss.vip.acme.com:8020/dir/otherDir/file.ext?cluster=hadoopCluster&format=seqFile&blkSize=128M>,
                  DataMetaParse::Uri.new('hdfs', nil, nil, 'node-geo-ss.vip.acme.com', 8020, 'dir/otherDir/file.ext',
                                       {'cluster' => 'hadoopCluster', 'format' => 'seqFile', 'blkSize' => '128M'}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host:3306/database?sql=select%20*%20from%20entity%20where%20id%20%3D%201>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', 3306, 'database',
                                       {'sql' => 'select * from entity where id = 1'}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20entity%20where%20id%20%3D%201>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => 'select * from entity where id = 1'}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20entity%20where%20id%20%3D%201%20and%20c2%20%3D%20%27abc%27>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q<select * from entity where id = 1 and c2 = 'abc'>}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20entity%20where%20id%20!%3D%201>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q|select * from entity where id != 1|}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20entity%20where%20id%20%3C%3E%201>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q|select * from entity where id <> 1|}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20entity%20where%20id%20%3E%3D%201>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q|select * from entity where id >= 1|}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20database.entity%20where%20id%20%3E%3D%201>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q|select * from database.entity where id >= 1|}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20entity%20where%20id%20in%20(1%2C2%2C3)>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q|select * from entity where id in (1,2,3)|}))

        assertUri(%q<oracle://DM_USER:DataMeta_PWD@db-host:3306/database?sql=select%20*%20from%20entity%20where%20id%20%3D%201>,
                  DataMetaParse::Uri.new('oracle', 'DM_USER', 'DataMeta_PWD', 'db-host', 3306, 'database',
                                       {'sql' => 'select * from entity where id = 1'}))

        assertUri(%q<mysql://DM_USER:DataMeta_PWD@db-host/database?sql=select%20*%20from%20database.entity%20where%20id%20like%20%27%25a%25%27>,
                  DataMetaParse::Uri.new('mysql', 'DM_USER', 'DataMeta_PWD', 'db-host', nil, 'database',
                                       {'sql' => %q|select * from database.entity where id like '%a%'|}))
    end

=begin rdoc
Check bad URLs, must raise errors:
=end
    def test_badUris
        assert_raise(ArgumentError) {
            DataMetaParse::Uri.new('file', 'blah', nil, nil, nil, 'dir/otherDir/file.ext', {})
        }

        assert_raise(ArgumentError) {
            DataMetaParse::Uri.new('file', nil, 'blah', nil, nil, 'dir/otherDir/file.ext', {})
        }

        assert_raise(ArgumentError) {
            DataMetaParse::Uri.new('file', nil, nil, 'blah', nil, 'dir/otherDir/file.ext', {})
        }

        assert_raise(ArgumentError) {
            DataMetaParse::Uri.new('file', nil, nil, nil, 8080, 'dir/otherDir/file.ext', {})
        }

        assert_raise(ArgumentError) { # password but no user, no good:
            DataMetaParse::Uri.new('http', nil, 'secret', 'www.domain.tld', nil, 'path/dir',
                                 {'qa' => 'aVal', 'qb' => 'bVal'})
        }
        # Hadoop Good Practice: disallow hdfs specifications without namenode
        assert_equal(nil, DataMetaParse::Uri.parse('hdfs:///dir/otherDir/file.ext'))

    end
end
