#!/usr/bin/env ruby
%w( dataMetaDom dataMetaByteSer ).each(&method(:require))

@source, @target = ARGV
DataMetaByteSer::helpDataMetaBytesSerGen __FILE__ unless @source && @target
DataMetaByteSer::helpDataMetaBytesSerGen(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaByteSer::helpDataMetaBytesSerGen(__FILE__, "Writables destination directory #{@target} is not a dir") unless File.directory?(@target)

@parser = DataMetaDom::Model.new
begin
    @parser.parse(@source, options={autoVerNs: true})
    DataMetaByteSer::genWritables(@parser, @target)
    puts "Byte Array serialization classes written to #{@target}. Done."
rescue Exception => e
   $stderr.puts "ERROR #{e.message}; #{@parser.diagn}"
   $stderr.puts e.backtrace.inspect
end
