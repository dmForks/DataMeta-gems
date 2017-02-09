#!/usr/bin/env ruby
# this script generates the SQL DDL for the DataMeta DOM core model
# Example, from gem root:
#    dataMetaOracleDdl.rb ../../../dataMeta/showCase.dmDom ../../../../../target/sql

%w(dataMetaDom dataMetaDom/ora dataMetaDom/help).each(&method(:require))

include DataMetaDom, DataMetaDom::OraLexer

@source, @target = ARGV
DataMetaDom::helpOracleDdl __FILE__ unless @source && @target
DataMetaDom::helpOracleDdl(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaDom::helpOracleDdl(__FILE__, "Oracle DDL destination directory #{@target} is not a dir") unless File.directory?(@target)

@parser = Model.new
begin
  @parser.parse(@source)
  puts @parser.enums.values.join("\n") if $DEBUG
  puts @parser.records.values.join("\n") if $DEBUG
  genDdl(@parser, @target)
  puts "Oracle DDL generated into #{@target}"
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@parser.diagn}"
   $stderr.puts e.backtrace.inspect
    exit 1
end
