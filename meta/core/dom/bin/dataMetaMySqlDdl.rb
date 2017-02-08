#!/usr/bin/env ruby
# this script generates the SQL DDL for the DataMeta DOM model
# Example, from gem root:
#    dataMetaMySqlDdl.rb ../../../dataMeta/showCase.dataMeta ../../../../../target/sql

%w(dataMetaDom dataMetaDom/mySql dataMetaDom/help).each(&method(:require))

include DataMetaDom, DataMetaDom::MySqlLexer

@source, @target = ARGV

DataMetaDom::helpMySqlDdl __FILE__ unless @source && @target
DataMetaDom::helpMySqlDdl(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaDom::helpMySqlDdl(__FILE__, "MySQL DDL destination directory #{@target} is not a dir") unless File.directory?(@target)

@parser = Model.new
begin
  @parser.parse(@source)
  puts @parser.enums.values.join("\n") if $DEBUG
  puts @parser.records.values.join("\n") if $DEBUG
  genDdl(@parser, @target)
  puts "MySQL DDL generated into #{@target}"
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@parser.diagn}"
   $stderr.puts e.backtrace.inspect
   exit 1
end
