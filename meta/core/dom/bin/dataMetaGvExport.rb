#!/bin/env ruby
%w( dataMetaDom dataMetaXtra ).each(&method(:require))
include DataMetaDom

ENTITY_FILL_COLOR='#CCEEFF'
ENUM_FILL_COLOR='#CCFFCC'
ENUM_LINE_COLOR='#00CC00'
ENTITY_LINE_COLOR='#000066'

def genGv(parser, outFileName)
  out = File.open(outFileName, 'wb')
out.puts <<GV_HEADER
digraph Model {
    ranksep=1.6;
    node [shape=box, fontcolor="black" style="rounded,filled" fontname="Consolas" fillcolor="#AAFFCC" pad=1.5 decorate=true fontsize=15 ];
    edge [arrowhead=vee] ;
GV_HEADER
  parser.records.each_value.each { |rec|
    ns, base = DataMetaDom::splitNameSpace(rec.name)
    out.puts %{  #{base} [fillcolor = "#{ENTITY_FILL_COLOR}" color="#{ENTITY_LINE_COLOR}"]}
  }
  parser.enums.values.each { |e|
    ns, base = DataMetaDom::splitNameSpace(e.name)
    out.puts %{  #{base} [fillcolor = "#{ENUM_FILL_COLOR}" color="#{ENUM_LINE_COLOR}"]}
  }

  parser.records.each_value.each { |rec|
    rec.refs.each { |ref|
      # can not use the dotted package notation, GraphViz interprets it differently
      # besides, with full names the graph becomes unreadable.
      ns, fromEntityBareName = splitNameSpace ref.fromEntity.name
      ns, toEntityBareName = splitNameSpace ref.toEntity.name
      case ref.type
        when Reference::RECORD
           out.puts %{  #{fromEntityBareName} -> #{toEntityBareName} } + \
              %{[ label="#{ref.fromField.name}" color="#{ENTITY_LINE_COLOR}"]}
        when Reference::ENUM_REF
          out.puts %{  #{fromEntityBareName} -> #{toEntityBareName} } +\
              %{[ label="#{ref.fromField.name}" color="#{ENUM_LINE_COLOR}"]}
      else
          # skip it
      end
    }
  }
  out.puts '}'
  out.close
end

def viewGv
  puts `dot -o#{@imageFile} -Tjpeg #{@gvFile}`
  if DataMetaXtra::Sys::WINDOWS
      @imageFile.gsub!('/','\\')
      irfanViewExe = %<#{ENV['PROGRAMFILES']}\\IrfanView\\i_view32.exe>
      shimgvwDll = %<#{ENV['SystemRoot']}\\System32\\shimgvw.dll>
      if File.file?(irfanViewExe) # if Irfanview is installed, use it because it works always faster than PhotoViewer
          system(%<start "#{File.basename(@domFile)}" "#{irfanViewExe}" #{@imageFile} /title=#{File.basename(@domFile)}>)
      elsif File.file?(shimgvwDll)
=begin
use the standard issue Windows PhotoViewer
if this runs too slow, run Color Calibration, or move the PhotoViewer window from one monitor to another:
if the PhotoViewer still is slow, install and use IrfanView 32 bit instead:
=end
          system(%<start "#{File.basename(@domFile)}" rundll32.exe #{shimgvwDll}, ImageView_Fullscreen #{@imageFile}>)
      else  # use default Windows viewer for jpeg if any
          system(%<start "#{File.basename(@domFile)}" #{@imageFile}>)
      end
  elsif DataMetaXtra::Sys::LINUX
      # on Linux, ise ImageMagick, can install it with: sudo yum install php-pecl-imagick
      system("display #{@imageFile} &")
      # can also use "gnome-open" under GDM
  else
      $stderr.puts %|Don't know how to run image view on "#{RUBY_PLATFORM}"|
  end

end

@domFile, @outPath = $*
raise %|DataMetaDOM source "#{@domFile}" is not a file| unless @domFile && File.file?(@domFile)
raise 'Output path is missing' unless @outPath
@outDir = File.dirname(@outPath)
raise %|Output directory "#{@outDir}" is not a directory| unless @outDir && File.directory?(@outDir)
# absolute path works best with viewer utilities and exporters too
@domBase = File.basename(@domFile, '.dmDom')
@gvFile = File.absolute_path(File.join(@outPath, @domBase + '.gv'))
@imageFile = File.absolute_path(File.join(@outPath, @domBase + '.jpeg'))


@parser = Model.new
begin
  @parser.parse @domFile
  genGv @parser, @gvFile
  viewGv
rescue Exception => e
   puts "ERROR #{e.message}#{@parser.diagn}"
   puts e.backtrace.inspect
end

