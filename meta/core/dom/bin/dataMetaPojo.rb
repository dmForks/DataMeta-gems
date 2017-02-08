#!/usr/bin/env ruby
# this script generates Java POJOs and the SQL DDL for the DataMeta DOM model
# Sample:
# mkdir ../../../../../target/pojo
# dataMetaPojo.rb ../../../dataMeta/showCase.dataMeta ../../../../../target/pojo

%w(dataMetaDom dataMetaDom/pojo dataMetaDom/help).each(&method(:require))

include DataMetaDom, DataMetaDom::PojoLexer

@source, @target = ARGV
DataMetaDom::helpPojoGen __FILE__ unless @source && @target
DataMetaDom::helpPojoGen(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaDom::helpPojoGen(__FILE__, "POJO destination directory #{@target} is not a dir") unless File.directory?(@target)

@parser = Model.new
begin
  @parser.parse(@source, options={autoVerNs: true})
  puts @parser.enums.values.join("\n") if $DEBUG
  puts @parser.records.values.join("\n") if $DEBUG
  genPojos(@parser, @target)
  puts "POJOs written to #{@target}. Done."
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@parser.diagn}"
   $stderr.puts e.backtrace.inspect
   exit 1
end
