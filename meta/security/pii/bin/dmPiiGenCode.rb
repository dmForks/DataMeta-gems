#!/usr/bin/env ruby

require 'dataMetaDom'
require 'dataMetaDom/record'
require 'dataMetaDom/field'
require 'dataMetaDom/ver'
require 'dataMetaDom/dataType'
require 'dataMetaPii'

L = Logger.new("#{File.basename(__FILE__)[0..-4]}.log", 0, 10_000_000)

L.datetime_format = '%Y-%m-%d %H:%M:%S'

=begin
For testing, run, for example:

    cat source.dmPii | piiGenCode.rb abstract java .tmp
=end
def help(errorText = nil)

    puts %Q|
Usage: #{File.basename(__FILE__)} <Scope> <ExportFormat> <OutputRoot> [ Namespace ]

Exports the PII definition into sources

Parameters:
   <Scope> - one of: #{DataMetaPii::Scope.constants.map{|c| DataMetaPii::Scope.const_get(c).to_s}.join(', ')}

   <ExportFormat>  - one of: #{DataMetaPii::ExportFmts.constants.map{|c| DataMetaPii::ExportFmts.const_get(c).to_s}.join(', ')}

   <OutputRoot> - must be a valid directory in the local file system.

   [ Namespace ] - for Java and Scala - package name, for Python - module name, for JSON - does not matter.

   DataMeta PII sources should be piped in.

|
    $stderr.puts(%Q<\nERROR: #{errorText}>) if errorText

    exit errorText ? 2 : 1
end

@scopeDef, @outFmtDef, @outDirName, @namespace = $*
help unless @scopeDef && @outFmtDef && @outDirName

@scope, @outFmt = [@scopeDef, @outFmtDef].map(&:to_sym)

help %q<Source is not piped in> if $stdin.tty?

puts %Q|
Exporting #{@scope} to #{@outFmt}:

Generating results to #{@outDirName}...

|

begin
    DataMetaPii.genCode(@scope, @outFmt, @outDirName, $stdin.read, @namespace)
    puts 'Done.'
rescue Exception => x
    L.error(%<#{x}\n#{DataMetaPii::INDENT}#{x.backtrace.join("\n#{DataMetaPii::INDENT}")}>)
    help x.to_s
end


