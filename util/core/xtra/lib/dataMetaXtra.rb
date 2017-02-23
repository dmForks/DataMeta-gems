$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'logger'

#Various extensions to the Ruby SDK addressing whatever shortcomings we run into.
module DataMetaXtra
    # Current version
    VERSION = '1.0.0'

    # Default Logger datetime format
    LOGGER_DTTM_FMT = '%Y-%m-%d %H:%M:%S'

# Constants to deal with the operational system, operational environment
    module Sys
        # Platform constant - +true+ if running under Microsoft Windows.
        WINDOWS = (/mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil

        # Platform constant - +true+ if running under Cygwin.
        CYGWIN = (/cygwin/ =~ RUBY_PLATFORM) != nil

        # Platform constant - +true+ if running under MacOS X.
        MAC_OS_X = (/darwin/ =~ RUBY_PLATFORM) != nil

        # Platform constant - +true+ if running under Linux.
        LINUX = (/linux|GNU/i =~ RUBY_PLATFORM) != nil

        # Platform constant - +true+ if running under any Unix environment: Linux, MacOS X or Cygwin.
        UNIX = LINUX || MAC_OS_X || CYGWIN

        # Who's running this program - this won't change as long as the program is running.
        OS_USER = ENV['USERNAME'] || ENV['USER']

        # What's the current user's home path in the filesystem.
        OS_USER_HOME= case
            when WINDOWS
                "#{ENV['HOMEDRIVE']}/#{ENV['HOMEPATH'].gsub(/\\/, '/')}"
            when CYGWIN
                "#{ENV['HOME']}"
                #"/cygdrive/#{ENV['HOMEDRIVE'][0, 1].downcase}#{ENV['HOMEPATH'].gsub(/\\/, '/')}"
            else # Linux, MacOS (verified)
                "#{ENV['HOME']}"
        end
    end
=begin rdoc
Builds a default logger for the given trollop opts and parser.
If the opts and parser passed, builds the logger according to the options,
with daily rollover and max size 10 M.

If no opts or no parser passed, returns the logger to STDOUT for the WARN level.

There is no point in creating a more generic method, the bare <tt>Logger.new</tt> call
creates a weekly logger with the 1M size, to STDOUT. Can call <tt>Logger.new('file.log')</tt>

The default level is DEBUG, therefore you may want change it

@param [Hash] opts standard Ruby options hash keyed by a sym, see individual options for details
@param [Trollop::Parser] parser optional Trollop parser to call "educate" on.
=end
    def defaultLogger(opts=nil, parser=nil)
        if opts && parser
            #noinspection RubyArgCount
            result = Logger.new(opts[:logFile] || 'dataMetaXtra.log', 'daily', 10*1024*1024)
            result.level = case opts[:level] ? opts[:level].downcase[0] : 'i'
               when 'd'
                   Logger::DEBUG
               when 'i'
                   Logger::INFO
               when 'w'
                   Logger::WARN
               when 'e'
                   Logger::ERROR
               else
                   parser.educate
                   raise "Invalid log level #{opts[:level]}"
            end
            result.datetime_format = '%Y-%m-%d %H:%M:%S'
            result
        else
            result = Logger.new($stdout)
            result.level = Logger::WARN
            result
        end
    end

=begin rdoc
Hack for Windows that often the name of the executable into the first argument:
Discard the first argument if any if it has the same base file name as the current runnable
Pass the caller's <tt>__FILE__</tt>.
=end
    def winArgHack(file)
        ARGV.shift if !ARGV.empty? && ARGV[0] && File.exist?(ARGV[0]) && File.basename(ARGV[0]) == File.basename(file)
    end

    # Empty block factory
    class ProcFactory
        # Creates a new Proc, Proc requires a block, that's why have to place it in a class in a method
        def create; Proc.new {} end
    end

=begin rdoc
New empty binding for evaluation to avoid exposing class variables

Require anything that you may need here outside of the block, it bubbles into here.
=end
    def nilBinding; ProcFactory.new.create.binding end

=begin rdoc
Adding some methods to the standard Ruby String class, useful to generate code.

For more useful String related methods, see {ActiveSupport's Inflections}[http://apidock.com/rails/ActiveSupport/Inflector/inflections]

=end
    module Str

        # Capitalize just first letter, leave everything else as it is.
        # In contrast to the standard method capitalize which leaves the tail lowercased.
        def capFirst(original)
            original[0].chr.upcase + original[1..-1]
        end

        # turn the first letter lowercase, leave everything else as it is.
        def downCaseFirst(original)
            original[0].chr.downcase + original[1..-1]
        end

=begin rdoc
Turns underscored into camelcase, with first letter of the string and each after underscore
turned uppercase and the rest lowercase. Useful for making class names.

Note that there is one good implementation in the {ActiveSupport gem}[http://apidock.com/rails/ActiveSupport/Inflector/inflections]
too.

Examples:
* +this_one_var+ => +ThisOneVar+
* +That_oThEr_vAR+ => +ThatOtherVar+

See also variablize.
=end
        def camelize(original)
            return original.downcase.capitalize if original =~ /[A-Z]+/ && original !~ /_/
            return original.capitalize if original !~ /_/
            original.split('_').map { |e| e.capitalize }.join
        end

=begin rdoc
Same as camelize but makes sure that the first letter stays lowercase,
useful for making variable names.

Example:
* +That_oTHer_vAr+ => +thatOtherVar+

See also camelize.
=end
        def variablize(original)
            return original.downcase if original =~ /[A-Z]+/ && original !~ /_/
            return original[0].downcase + original[1..-1] if original !~ /_/
            camelized = original.split('_').map { |e| e.capitalize }.join
            camelized[0].downcase + camelized[1..-1]
        end
        module_function :camelize, :variablize, :capFirst, :downCaseFirst
    end

=begin rdoc
Returns a log name for the given filename, replacing the extension with "<tt>log</tt>".

Normally would pass <tt>__FILE__</tt> to this method.

To get a full path, can call <tt>File.extend_path</tt>
=end
    def logName(fullPath); "#{fullPath.chomp(File.extname(fullPath))}.log"  end

    # Turns the given instance to milliseconds as integer.
    def toMillis(time); (time.to_f * 1000).to_i end

    # Turns the given instance to microseconds as integer.
    def toMicros(time); (time.to_f * 1000000).to_i end

    # likely to be lacking precision
    # UTC millis of now.
    # not delegated to {#toMillis} because method calls are still relatively expensive in Ruby, especially in
    # older versions
    def nowMillis; (Time.now.utc.to_f * 1000).to_i end

    # UTC seconds of now.
    def nowSeconds; Time.now.utc.to_i end

    # UTC micros of now.
    # not delegated to {#toMicros} because method calls are still relatively expensive in Ruby, especially in
    # older versions
    def nowMicros; (Time.now.utc.to_f * 1000000).to_i end

    # Current-Directory-Basename - dash - seconds.
    def nowWdSeconds; "#{File.basename(Dir.getwd)}-#{nowSeconds}" end


=begin rdoc
Collects several glob patterns to this array. This is so simple that can be inlined.

@param [Array] arr array to append the globs to
@param [Array] patterns array of glob patterns

@return [Array] flattenned source array with the filenames by the glob patterns appended to the end
=end
    def appendGlobs(arr, patterns); patterns.each { |p| arr << Dir.glob(p) }; arr.flatten end

    # Turns this array to a PATH list according to <tt>File::PATH_SEPARATOR</tt>.
    def toPathList(arr); arr.join(File::PATH_SEPARATOR) end

    module_function :winArgHack, :defaultLogger, :nilBinding, :appendGlobs, :toPathList,
                    :nowWdSeconds, :logName, :toMillis, :toMicros, :nowMillis, :nowSeconds, :nowMicros
end
