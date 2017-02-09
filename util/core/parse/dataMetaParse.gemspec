require './lib/dataMetaParse'
Gem::Specification.new do |s|
  s.name = 'dataMetaParse'
  s.has_rdoc = 'yard'
  s.version = DataMetaParse::VERSION
  s.date = '2017-01-15'
  s.summary = 'DataMeta Parser commons'
  s.description = 'DataMeta Parser commons; common rules and some reusable grammars'
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

  s.add_dependency('treetop', '~> 1.6', '>= 1.6.8')
  s.required_ruby_version = '>=2.0.0'
  s.requirements << 'No specific requirements'
  s.test_files = %w(test/test_numbers.rb test/test_uriParser.rb test/numbers.treetop test/test_helper.rb)
end
