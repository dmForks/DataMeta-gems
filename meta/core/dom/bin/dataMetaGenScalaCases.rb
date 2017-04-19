#!/usr/bin/env ruby
# this script generates Java POJOs and the SQL DDL for the DataMeta DOM model
# Sample:
# mkdir ../../../../../target/pojo
# dataMetaPojo.rb ../../../dataMeta/showCase.dmDom ../../../../../target/pojo

%w(dataMetaDom dataMetaDom/scala dataMetaDom/help).each(&method(:require))

include DataMetaDom, DataMetaDom::ScalaLexer

@source, @target = ARGV
DataMetaDom::helpScalaGen __FILE__ unless @source && @target
DataMetaDom::helpScalaGen(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaDom::helpScalaGen(__FILE__, "Case Classes destination directory #{@target} is not a dir") unless File.directory?(@target)

@parser = Model.new
begin
  @parser.parse(@source, options={autoVerNs: true})
  genCaseClasses(@parser, @target)
  puts "Scala Case Classes written to #{@target}. Done."
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@parser.diagn}"
   $stderr.puts e.backtrace.inspect
   exit 1
end
