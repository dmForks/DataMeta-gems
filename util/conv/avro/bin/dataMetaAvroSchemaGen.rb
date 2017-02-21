#!/usr/bin/env ruby

%w( dataMetaDom dataMetaAvro ).each(&method(:require))

# sample arguments from the gem's root
# dataMetaAvroSchemaGen.rb ../../../test/dmDom/showCase.dmDom ../../../../src/test/avsc

@source, @target = ARGV
DataMetaAvro::helpAvroSchemaGen __FILE__ unless @source && @target
DataMetaAvro::helpAvroSchemaGen(__FILE__, "DataMetaDom source #{@source} is not a file") unless File.file?(@source)
DataMetaAvro::helpAvroSchemaGen(__FILE__, "Schema destination directory #{@target} is not a dir") unless File.directory?(@target)

puts "Generating #{@source} into #{@target}"

@parser = DataMetaDom::Model.new
begin
    @parser.parse(@source)
    DataMetaAvro::genSchema(@parser, @target)
rescue Exception => e
   puts "ERROR #{e.message}; #{@parser.diagn}"
   puts e.backtrace.inspect
end
