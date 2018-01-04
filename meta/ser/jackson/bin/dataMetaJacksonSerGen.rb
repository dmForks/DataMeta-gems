#!/usr/bin/env ruby
%w( dataMetaDom dataMetaJacksonSer dataMetaJacksonSer/util ).each(&method(:require))

@source, @target, @formatSpec = ARGV
DataMetaJacksonSer::helpDataMetaJacksonSerGen __FILE__ unless @source && @target
DataMetaJacksonSer::helpDataMetaJacksonSerGen(__FILE__, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
DataMetaJacksonSer::helpDataMetaJacksonSerGen(__FILE__, "Jacksonables destination directory #{@target} is not a dir") unless File.directory?(@target)

@format = if @formatSpec.nil?
  DataMetaJacksonSer::JAVA_FMT # default to Java
else
  fmt = @formatSpec.to_sym
  case fmt
    # this should be verified (asserted) by the API methods too, but they would raise an error
    # instead of showing help.
    when DataMetaJacksonSer::JAVA_FMT, DataMetaJacksonSer::SCALA_FMT
      fmt
    else
      DataMetaJacksonSer::helpDataMetaJacksonSerGen(__FILE__,
          %/Unsupported output format "#{@formatSpec}", use "java" or "scala"/)
  end
end

puts "Output format: #{@format}"

@parser = DataMetaDom::Model.new
begin
    @parser.parse(@source, options={autoVerNs: true})
    DataMetaJacksonSer::genJacksonables(@parser, @target, @format)
    puts "Jackson serialization classes written to #{@target}. Done."
rescue Exception => e
  indent = ' ' * 4
  $stderr.puts %/ERROR #{e.message}; #{@parser.diagn}
#{indent}#{e.backtrace.join("\n#{indent}")}
/
end
