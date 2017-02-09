require './lib/dataMetaByteSer'
Gem::Specification.new do |s|
  s.name = 'dataMetaByteSer'
  s.has_rdoc = 'yard'
  s.version = DataMetaByteSer::VERSION
  s.date = '2017-01-15'
  s.summary = 'DataMeta Byte Array Serializers Gen'
  s.description = 'Generates serializers of DataMeta objects to/from byte arrays, which can be used with Hadoop, BigTable and beyond.'
  s.authors = ['Michael Bergens']
  s.email = %q{michael.bergens@gmail.com}


  allFiles = []
  allFiles << Dir.glob('lib/**/*')
  allFiles << Dir.glob('tmpl/**/*')
  allFiles << Dir.glob('bin/**/*').select{|n| case File.basename(n) when 'deploy.rb', 'reinstall.rb' then false else true end}
  allFiles << Dir.glob('test/**/*') # include all tests
  allFiles << 'README.md' << 'Rakefile' << 'PostInstall.txt' << '.yardopts' << 'History.md'
  s.files = allFiles.flatten.select{ |n| File.file?(n)}
  puts "All files in this gem: #{s.files.join(', ')}"
  s.homepage = 'https://github.com/eBayDataMeta'
  s.license = 'Apache-2.0'

  s.add_dependency 'dataMetaDom', '~> 1.0', '>= 1.0.0'
  s.required_ruby_version = '>=2.1.1'
  s.requirements << 'Hadoop libraries'
  s.test_files = %w(test/test_dataMetaByteSer.rb)
  s.executables = %w(dataMetaByteSerGen.rb)
  s.default_executable = s.executables[0]
end
