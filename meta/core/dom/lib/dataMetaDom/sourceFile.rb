$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set dataMetaDom/docs dataMetaDom/ver).each { |r| require r }

module DataMetaDom
=begin rdoc
A Model coupled with the DataMeta DOM source file info

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class SourceFile < VerDoccable
=begin rdoc
The directory to this source file.
=end
    attr_reader :path

=begin rdoc
The name of this source file in the directory indicated by the path property.
=end
    attr_reader :name

=begin rdoc
Unique key of this source file to use in hash maps, the absolute path to avoid duplicates by
different ways to point to the file, turned into a symbol.
=end
    attr_reader :key

=begin rdoc
The namespace associated with the source file.
=end
    attr_reader :namespace

=begin rdoc
Current source line.
=end
    attr_reader :line

=begin rdoc
Current source line number
=end
    attr_reader :lineNum

=begin rdoc
Create an instance with the given parameters.
* Parameters:
  * +path+ - directory where the source file is located
  * +name+ - the base name of this source file
  * +line+ - source line if any, useful when creating the source reference from the code when source is not trivial.
  * +lineNum+ - line number, useful when creating the source reference from the code
  * +namespace+ - namespace associated with this source file, useful when creating the source reference from the code
=end
    def initialize(path, name, line = nil, lineNum = 0, namespace = nil)
        #noinspection RubyArgCount
        super()
        @path = path
        @name = name
        @namespace = namespace
        # use the Absolute Path to avoid double-dipping via different subdir references
        @key = File.absolute_path("#{@path}#{File::SEPARATOR}#{@name}").to_sym
        @lineNum = lineNum
        @line = line # nil interpolates to an empty string
    end

=begin rdoc
Create a shapshot of the source file information, useful for saving a status about an element currently parsed.
Can not use this instance - as the parsing progresses, the stateful information will change.
=end
    def snapshot # for the history
        snap = SourceFile.new(@path, @name, @line, @lineNum, @namespace)
        snap.ver = Ver.new(self.ver.full)
        snap
    end

=begin rdoc
Parses this DataMeta DOM source into the given Model.
=end
    def parse model
        while nextLine
            puts "Source: #{@line}" if $DEBUG
            next if docConsumed?(self)
            if (newVer = VerDoccable.verConsumed?(self))
                raise RuntimeError, "Only one version definition allowed, second one found in line #{@lineNum}" if self.ver
               self.ver = newVer
               model.ver = newVer # plant it straight into the model per the latest design
               raise ArgumentError,
                     %<Model version already defined as #{model.ver} but the file #{@path} tries to redefine it to #{newVer}.
This is not allowed: all included files should define same version> unless model.ver && newVer == model.ver
               next
            end
            case @line
            # treat the namespace operator as a special case
                when /^\s*#{NAMESPACE}\s+([\w\.]+)$/
                    @namespace = $1
                    next
                when /^\s*#{INCLUDE}\s+(\S+)$/
                    model.sources.queue "#{$1}.dmDom"
                    next
                else
                    isTokenOk = false
                    MODEL_LEVEL_TOKENS.each { |c|
                        isTokenOk = c.consumed?(model, self)
                        if isTokenOk
                            resetEntity
                            break
                        end
                    }
                    raise "Syntax error; #{model.diagn}" unless isTokenOk

            end

        end # while
    end

=begin rdoc
Advances a line, skipping empty lines and comments.
Parameter:
* +verbatim+ - pass true to maintain formatting and keep empty lines
=end
    def nextLine(verbatim = false)
        @file = File.open("#{@path}#{File::SEPARATOR}#{@name}") unless defined?(@file) && @file
        while (line = @file.gets)
            unless line
                @file.close
                nil
            end
            @lineNum += 1
            return (@line = line) if verbatim
            @line = line.chomp.strip

            case @line
                when '', /^\s*#.*$/ # skip comments and empty lines
                    next
                else
                    return @line
            end
        end
    end

=begin rdoc
Full name of this source file, absolute path. Derived from the key property turned into a string.
=end
    def fullName; @key.to_s end

=begin rdoc
Textual representation of this source file reference, includes line number and the current source line.
=end
    def to_s; "#{fullName}##{@lineNum}{{#{@line}}}" end # file name, line number and line
end

end
