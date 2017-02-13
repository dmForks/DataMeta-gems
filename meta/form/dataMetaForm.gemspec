require './lib/dataMetaForm'
Gem::Specification.new do |s|
  s.name = 'dataMetaForm'
  s.has_rdoc = 'yard'
  s.version = DataMetaForm::VERSION
  s.date = '2017-02-10'
  s.summary = 'DataMeta File Formats'
  s.description = 'DataMeta File Formats - to complement the data structures'
  s.authors = ['Michael Bergens']
  s.email = %q{michael.bergens@gmail.com}

  allFiles = []
  allFiles << Dir.glob('lib/**/*')
  allFiles << Dir.glob('grammar/**/*')
  allFiles << Dir.glob('tmpl/**/*')
  allFiles << Dir.glob('bin/**/*').select{|n| case File.basename(n) when 'deploy.rb', 'reinstall.rb' then false else true end}
  allFiles << Dir.glob('test/**/*') # include all tests
  allFiles << 'README.md' << 'Rakefile' << 'PostInstall.txt' << '.yardopts' << 'History.md'
  s.files = allFiles.flatten.select{ |n| File.file?(n)}
  puts "All files in this gem: #{s.files.join(', ')}"
  s.homepage = 'https://github.com/eBayDataMeta'
  s.license = 'Apache-2.0'

  s.required_ruby_version = '>=2.0.0'
  s.add_dependency('dataMetaParse', '~> 1.0', '>= 1.0.0')
  s.requirements << 'No special requirements'
end
