#!/bin/env ruby

# This script replaces references to DataMetaDOM version with a new version
# In the source files as well as config files.

require 'dataMetaDom'
require 'dataMetaDom/ver'
require 'dataMetaDom/help'

@path, @ns, @globs_def, @ver_from_spec, @ver_to_spec = $*

def help(errorText = nil)
    DataMetaDom.help(__FILE__, 'Source reversioner', %q~<Path> <NS> <CSV-globs> <Ver-From> <Ver-To>

Where:
    * Path - starting path to look for the files to re-version
    * NS - Namespace, such as Java/Scala package
    * CVS-globs - comma-separated file patterns, in regular filesystem globbing format
    * Ver-From - Source version or an asterisk for any version. Example: 1.2.1
    * Ver-To - Target version. Example: 1.2.2

Examples of arguments:
    Replace on all Java and Scala files starting from the src/main/com/acme, any prior DataMeta version with 1.2.3:
        src/main/com/acme com.acme.svc.schema.dom '*.java,*.scala' '*' 1.2.3

    Starting from the current directory, replace on all Scala and config files, DataMeta version 1.2.1 with 1.2.3:
        . com.acme.svc.schema.dom '*.conf,*.scala' 1.2.1 1.2.3

Note the single quotes for the file glob patterns and the "star" specification of the source version: this is to
prevent the shell to glob before passing the result to the program.

Note that there is no relation between the path and the namespace; only Java still enforces such relation therefore
we do not want to be dependent on it.

~, errorText)
end

help 'Target path is missing' unless @path && !@path.empty?
help %<"#{@path}" is not a valid path!> unless File.directory?(@path)
help %<"#{@ns}" is not a valid namespace!> unless @ns.is_a?(String) && @ns =~ /^[\w_\.]+$/
help 'No file globs specified' unless @globs_def && !@globs_def.empty?
if @ver_from_spec == '*'
    @ver_from = nil
else
    begin
        @ver_from = DataMetaDom::SemVer.new(@ver_from_spec)
    rescue Exception => x
        help "Source version: #{x.message}"
    end
end

begin
    @ver_to = DataMetaDom::SemVer.new(@ver_to_spec)
rescue Exception => x
    help "Target version: #{x.message}"
end

begin
    puts "Reversioning #{@globs_def} files starting from #{@path} to #{@ver_to}"
    DataMetaDom::Ver.reVersion(@path, @ns, @globs_def.split(','), @ver_from, @ver_to)
    puts 'Done.'
rescue Exception => x
    $stderr.puts %<ERROR #{x.message}
    #{x.backtrace.join("\n\t")}>
    exit 1
end
