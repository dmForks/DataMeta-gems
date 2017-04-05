#!/usr/bin/env ruby
%w( dataMetaDom dataMetaJacksonSer ).each(&method(:require))

@source, @target = ARGV
DataMetaJacksonSer::helpDataMetaJacksonSerGen __FILE__ unless @source && @target
DataMetaJacksonSer::helpDataMetaJacksonSerGen(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaJacksonSer::helpDataMetaJacksonSerGen(__FILE__, "Jacksonables destination directory #{@target} is not a dir") unless File.directory?(@target)

@parser = DataMetaDom::Model.new
begin
    @parser.parse(@source, options={autoVerNs: true})
    DataMetaJacksonSer::genJacksonables(@parser, @target)
    puts "Jackson serialization classes written to #{@target}. Done."
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@parser.diagn}"
   $stderr.puts e.backtrace.inspect
end
