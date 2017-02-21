require './lib/dataMetaProtobuf'
Gem::Specification.new do |s|
  s.name = 'dataMetaProtobuf'
  s.has_rdoc = 'yard'
  s.version = DataMetaProtobuf::VERSION
  s.date = '2017-02-19'
  s.summary = 'DataMeta Protobuf'
  s.description = 'DataMeta DOM to Protobuf IDL generator'
  s.authors = ['Michael Bergens']
  s.email = %q{michael.bergens@gmail.com}

  allFiles = []
  allFiles << Dir.glob('lib/**/*')
  allFiles << Dir.glob('bin/**/*').select{|n| case File.basename(n) when 'deploy.rb', 'reinstall.rb' then false else true end}
  allFiles << Dir.glob('test/**/*') # include all tests
  allFiles << 'README.md' << 'Rakefile' << 'PostInstall.txt' << '.yardopts' << 'History.md'
  s.files = allFiles.flatten.select{ |n| File.file?(n)}
  puts "All files in this gem: #{s.files.join(', ')}"
  s.homepage = 'https://github.com/eBayDataMeta'
  s.license = 'Apache-2.0'

  s.add_dependency('dataMetaDom', '~> 1.0', '>= 1.0.1')
  s.add_dependency('google-protobuf', '~> 3.2', '>= 3.2.0')
  s.required_ruby_version = '>=2.1.0'
  s.requirements << 'No special requirements'
  s.test_files = %w(test/test_dataMetaProtobuf.rb)
  s.executables = %w(dataMetaProtobufGen.rb)
  s.default_executable = s.executables[0]
end
