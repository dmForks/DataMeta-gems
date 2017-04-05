require './lib/dataMetaDom'
Gem::Specification.new do |s|
    s.name = 'dataMetaDom'
    s.has_rdoc = 'yard'
    s.version = DataMetaDom::VERSION
    s.date = '2017-04-03'
    s.summary = 'DataMeta DOM'
    s.description = 'DataMeta DOM classes and runnables'
    s.authors = ['Michael Bergens']
    s.email = %q{michael.bergens@gmail.com}

    allFiles = []
    allFiles << Dir.glob('lib/**/*')
    allFiles << Dir.glob('tmpl/**/*')

    allFiles << Dir.glob('bin/**/*').select { |n|
        case File.basename(n) when 'deploy.rb', 'reinstall.rb' then false else true end
    }

    allFiles << Dir.glob('test/**/*') # include all tests
    allFiles << 'README.md' << 'Rakefile' << 'PostInstall.txt' << '.yardopts' << 'History.md'

    s.files = allFiles.flatten.select { |n| File.file?(n) }

    puts "All files in this gem: #{s.files.join(', ')}"
    s.homepage = 'https://github.com/eBayDataMeta'

    s.license = 'Apache-2.0'

    s.add_dependency('dataMetaXtra', '~> 1.0', '>= 1.0.0')
    s.add_dependency('typesafe_enum', '~> 0.1', '>= 0.1.7')
#    s.add_dependency('libxml-ruby', '~> 2.6', '>= 2.6.0')
    s.required_ruby_version = '>=2.1.1'
    #s.requirements << 'A powerful CPU'
    s.test_files = 'test/test_dataMetaDom.rb'
    s.executables = %w(dataMetaPojo.rb dataMetaMySqlDdl.rb dataMetaSameFullJ.rb
                       dataMetaSameIdJ.rb dataMetaGvExport.rb dataMetaOracleDdl.rb dataMetaReVersion.rb)
    s.default_executable = s.executables[0]
end
