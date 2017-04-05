require './lib/dataMetaJacksonSer'
Gem::Specification.new do |s|
  s.name = 'dataMetaJacksonSer'
  s.has_rdoc = 'yard'
  s.version = DataMetaJacksonSer::VERSION
  s.date = '2017-03-31'
  s.summary = 'DataMeta JSON Serializers Gen using Fast XML Jackson'
  s.description = 'Generates serializers of DataMeta objects to/from JSON using Fast XML Jackson'
  s.authors = ['Michael Bergens']
  s.email = %q{michael.bergens@gmail.com}


  allFiles = []
  allFiles << Dir.glob('lib/**/*')
# There are no templates in this project yet, but we may create them later, like for a migration switch.
#  allFiles << Dir.glob('tmpl/**/*')
  allFiles << Dir.glob('bin/**/*').select{|n| case File.basename(n) when 'deploy.rb', 'reinstall.rb' then false else true end}
  allFiles << Dir.glob('test/**/*') # include all tests
  allFiles << 'README.md' << 'Rakefile' << 'PostInstall.txt' << '.yardopts' << 'History.md'
  s.files = allFiles.flatten.select{ |n| File.file?(n)}
  puts "All files in this gem: #{s.files.join(', ')}"
  s.homepage = 'https://github.com/eBayDataMeta'
  s.license = 'Apache-2.0'

  s.add_dependency 'dataMetaDom', '~> 1.0', '>= 1.0.4'
  s.required_ruby_version = '>=2.1.1'
  s.requirements << 'Hadoop libraries'
  s.test_files = %w(test/test_dataMetaJacksonSer.rb)
  s.executables = %w(dataMetaJacksonSerGen.rb)
  s.default_executable = s.executables[0]
end
