#!/usr/bin/env ruby
# this script generates Full Compare DataMetaSame implementors
# Sample:
# mkdir ../../../../../target/pojo
# dataMetaSameFullJ.rb ../../../dataMeta/showCase.dmDom ../../../../../target/pojo

%w(dataMetaDom dataMetaDom/pojo dataMetaDom/help).each(&method(:require))

source, target = ARGV
raise ArgumentError, 'Usage: source DataMeta DOM, target directory' unless source && target
DataMetaDom::PojoLexer.dataMetaSameRun DataMetaDom::PojoLexer::FULL_COMPARE, __FILE__, source, target

puts "All-fields DataMeta-Sames written to #{target}. Done."
