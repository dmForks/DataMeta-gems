require './lib/dataMetaBuild'
Gem::Specification.new do |s| # http://guides.rubygems.org/specification-reference/
    s.name = 'dataMetaBuild'
    s.has_rdoc = 'yard'
    s.version = DataMetaBuild::VERSION
    s.date = '2017-01-15'
    s.summary = 'Build Utilities'
    s.description = 'DataMeta Utilities for building applications'
    s.authors = ['Michael Bergens']
    s.email = %q{michael.bergens@gmail.com}

    allFiles = []
    allFiles << Dir.glob('lib/**/*')
    allFiles << Dir.glob('bin/**/*').select{|n| case File.basename(n) when 'deploy.rb', 'reinstall.rb' then false else true end}
    allFiles << Dir.glob('test/**/*') # include all tests
    allFiles << 'Rakefile' << 'PostInstall.txt' << '.yardopts' << 'README.md'
    s.files = allFiles.flatten.select { |n| File.file?(n) }
    puts "All files in this gem: #{s.files.join(', ')}"
    s.homepage = 'https://github.com/eBayDataMeta'
    s.license = 'Apache-2.0'

    # these options do not work with our version of rvm, use dataMetaReDoc.rb script on the dataMetaNewGem gem.
    s.rdoc_options << '--title' << '--line-numbers' << '--all' << "--title=dataMetaBuild-#{s.version}" <<
            '--main' << 'README.rdoc'

#  s.required_ruby_version = '>=2.0.0'
#  s.requirements << 'fileutils'
    s.test_files = %w(test/test_dataMetaBuild.rb)
    s.executables = %w(dataMetaMvnDepsPaths.rb)
    s.default_executable = s.executables[0]
end
