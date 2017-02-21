#!/usr/bin/env ruby

%w( dataMetaDom dataMetaProtobuf ).each(&method(:require))

require 'dataMetaDom'
require 'dataMetaProtobuf'

@source = $*[0]

DataMetaProtobuf.helpProtobufGen __FILE__, %q<Argument missing: pass the name of the file with DataMeta DOM source to convert> unless @source
DataMetaProtobuf.helpProtobufGen __FILE__, %<"#{@source}" is not a valid file> unless File.file?(@source)

@model = DataMetaDom::Model.new
begin
    @model.parse(@source)
    puts DataMetaProtobuf.genSchema(@model)
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@model.diagn}"
   $stderr.puts e.backtrace.join("\n\t")
end
