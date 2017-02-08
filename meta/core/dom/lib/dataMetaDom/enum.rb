$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set dataMetaDom/docs dataMetaDom/ver).each { |r| require r }

module DataMetaDom

=begin rdoc
Worded enum, enumeration expressed as a list of words, each word consisting of alphanumerical symbols only.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Enum < VerDoccable
=begin rdoc
The full name of the enum, including namespace if any
=end
    attr_reader :name

=begin rdoc
Attempts to consume/parse an enum from the given source on the given model, returns it if succeeds, returns +nil+ otherwise.
* Parameters
  * model - an instance of Model
  * src - an instance of SourceFile
=end
    def self.consumed?(model, src)
        src.line =~ /^\s*#{ENUM}\s+(\w+)$/ ? model.addEnum(Enum.new(combineNsBase(
             nsAdjustment(src.namespace, model.options, src), $1)).parse(src)) : nil
    end

=begin rdoc
Creates an instance for the given name, initializes internal variables.
=end
    def initialize(name); @name = name.to_sym; @map = {}; @format = nil; @counter = -1 end

# Keyword for this entity - +enum+ literally.
    def sourceKeyWord; ENUM end

=begin rdoc
Adds a word to the given enum - use judiciously, when building an Enum from memory.
To parse DataMeta DOM source, use the consumed? method.
=end
    def addKey(word)
        raise "Duplicate value '#{word}' in the enum '#@name'" if (@map.key?(word))
        @counter += 1
        @map[word] = @counter # ordinal
    end

=begin rdoc
Parses the keys from the current line on the given source, yields one key at a time.
Used by the parse method.
* Parameter:
  * +source+ - the instance of the SourceFile.
=end
    def getKeys(source)
        newVals = source.line.split(/[\s,]+/)
        puts newVals.join("|") if $DEBUG
        newVals.each { |v|

            raise "Invalid worded enum '#{v}', must start with #{ID_START}" \
            ", line ##{source.lineNum}" unless v =~ /^#{ID_START}\w*$/
            yield v.to_sym
        }
    end

=begin rdoc
Returns the ordinal enum value for the given word.
=end
    def ordinal(word); @map[word] end

=begin rdoc
Opposite to ordinal, for the given ordinal returns the word.
=end
    def [](ord); @map.invert[ord] end

=begin rdoc
All words defined on this enum, sorted alphabetically, *not* by enum order.
=end
    def values; @map.keys.sort end

# Raw values, in the order in which they were inserted
    def rawVals; @map.keys end

=begin
Determines if this enum is equal or an extention of the other. Extension means, it contains the whole other
enum plus more members at the tail.

Returns: +:ne+ if neither equal nor extension, +:eq+ if equal, +:xt+ if extension.
=end
    def isEqOrXtOf(other)
       return :eq if @map.keys == other.rawVals
       other.rawVals.each_index{ |x|
          return :ne if @map.keys[x] != other.rawVals[x]
       }
       :xt
    end

    # All ordinals on this enum, sorted as integer values.
    def keys; @map.values.sort end

# Textual representation of this enum - a list of words separated by commma.
    def to_s; "Enum #{@name}(#{@map.keys.join(', ')}, ver=#{self.ver})" end

=begin rdoc
Parses the given source into current instance. See the consumed? method for the details.
* Parameter:
  * +source+ - the instance of SourceFile.
=end
    def parse(source)
        while (line = source.nextLine)

            case line
                when /^\s*#{END_KW}\s*$/
                    self.ver = source.ver unless self.ver
                    raise "Version missing for the enum #{name}" unless self.ver
                    self.docs = source.docs.clone if source.docs
                    source.docs.clear
                    return self
                else
                    getKeys(source) { |k| addKey k }
            end # case
        end # while line
        self
    end # def parse
end #class Enum

end
