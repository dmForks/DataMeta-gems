require './lib/dataMetaXtra'
Gem::Specification.new do |s|
  s.name = 'dataMetaXtra'
  s.has_rdoc = 'yard'
  s.version = DataMetaXtra::VERSION
  puts "Version used: #{s.version}"
  s.date = '2017-01-15'
  s.summary = 'Small enhancements to a few Ruby standard classes.'
  s.description = 'A few small enhancements to some standard Ruby classes in one place convenient place.'
  s.authors = ['Michael Bergens']
  s.email = %q{michael.bergens@gmail.com}

  allFiles = Dir.glob('lib/**/*') << %W(README.md Rakefile PostInstall.txt .yardopts History.md Manifest.txt)
  s.files = allFiles.flatten.select{ |n| File.file?(n)}.sort
  puts "All files in this gem: #{s.files.join(', ')}"
  s.homepage = 'https://github.com/eBayDataMeta'
  s.license = 'Apache-2.0'


  #s.required_ruby_version = '>= 1.9.3'
#  s.add_dependency('rake', '>= 0.9')
#  s.requirements << 'fileutils set'
  #s.test_files = Dir.glob('test/tc_*.rb')
  #s.test_files = 'test/test_dataMetaXtra.rb'
end
