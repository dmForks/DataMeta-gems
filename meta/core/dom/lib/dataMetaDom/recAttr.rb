$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set).each { |r| require r }

module DataMetaDom

=begin rdoc
Record Attribute such as unique fields set, identity information, indexes, references etc
the common structure is like this:
keyword (hint1, hint2, hint3...) arg1, arg2

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class RecAttr

=begin rdoc
The keyword for the attribute.
=end
    attr_reader :keyword

=begin rdoc
A Set of hints, empty set if there are no hints on this attribute.
=end
    attr_reader :hints

=begin rdoc
Arguments on this attribute if any, an array in the order as listed in the DataMeta DOM source. Order is important,
for example, for an identity.
=end
    attr_reader :args

=begin rdoc
Unique key for the given attribute to distinguish between those and use in a map. Rebuilt by getKey method
defined on the subclasses.
=end
    attr_reader :key

=begin rdoc
Determines if this attribute has the given hint.
=end
    def hasHint?(hint)
        @hints.member?(hint)
    end

=begin rdoc
Creates an instance for the given keyword.
=end
    def initialize(keyword)
        @keyword = keyword.to_sym
        raise "Unsupported keyword #@keyword" unless REC_ATTR_KEYWORDS.member?(@keyword)
        @args = []; @hints = Set.new
    end

=begin rdoc
Adds the given argument, updates the key
=end
    def addArg(val)
        @args << val.to_sym
        updateKey
        self
    end

=begin rdoc
Adds the given hint.
=end
    def addHint(val); @hints << val end

=begin rdoc
Adds an array of arguments.
=end
    def addArgs(vals); vals.each { |v| addArg v }; self end

=begin rdoc
Adds a collection of hints.
=end
    def addHints(vals); vals.each { |h| addHint h }; self end

=begin rdoc
Updates the key, returns self for call chaining
=end
    def updateKey; @key = getKey; self end

=begin rdoc
Returns the count of arguments.
=end
    def length; @args.length end

=begin rdoc
Returns the arguments in the given position, zero-based.
=end
    def [](index); @args[index] end


=begin rdoc
Joins the arguments with the given delimiter.
=end
    def join(delimiter); @args.join(delimiter) end

=begin rdoc
Parses this instance from the given source.
* Parameter:
  * +source+ - an instance of SourceFile
=end
    def parse(source)
        @sourceRef = source.snapshot
        line = source.line
        recAttrMatch = line.scan(/^\s*(\w*)\s*(\([^\)]+\))?\s+(.+)$/)
        raise "Invalid record attribute spec '#{line}'" unless recAttrMatch
        keyw, hintList, argList = recAttrMatch[0]
        raise "Wrong keyword '#{keyw}', '#@keyword' expected instead" unless keyw && keyw.to_sym == @keyword
        @args = argList.split(/[\(\)\s\,]+/).map { |a| a.to_sym }
        if hintList
            @hints = Set.new hintList.split(/[\(\)\s\,]+/).select { |h| !h.strip.empty? }.map { |h| h.strip.to_sym }
        else
            @hints = Set.new
        end
    end

# textual representation of this instance
    def to_s; "#@keyword:#@key; #@sourceRef" end

    private :initialize
end

=begin rdoc
The record attribute with the unordered set of arguments.
See the RecAttrList for the ordered list implementation.
=end
class RecAttrSet < RecAttr

# Unordered unique set of the arguments
    attr_reader :argSet

# Creates an instance with the given keyword
    def initialize(keyword); super(keyword); @argSet = Set.new end

# Engages the super's parse method via the alias
    alias :recAttrParse :parse

# Determines if the instance has the given argument
    def hasArg?(arg); argSet.member?(arg) end

# Builds textual for the set of the arguments, for diagnostics.
    def argSetTextual; @argSet.map { |a| a.to_s }.sort.join(':') end

# Builds the unique key for the set of arguments on the instance
    def getKey; argSetTextual.to_sym end

# Adds the given argument to the instance
    def addArg(val)
        k = val.to_sym
        raise "Duplicate arg #{k} in the set of #{argSetTextual}" if @argSet.member?(k)
        @argSet << k
        #RecAttr.instance_method(:addArg).bind(self).call k - fortunately, overkill in this case, can do with just:
        super k
    end

=begin rdoc
Parses the instance from the given source.
* Parameters
  * +src+ - an instance of SourceFile
=end
    def parse(src)
        recAttrParse(src)
        # look if there are any duplicates, if there are it's an error:
        counterHash = Hash.new(0)
        args.each { |a| k=a.to_sym; counterHash[k] += 1 }
        dupes = []; counterHash.each { |k, v| dupes << k if v > 1 }
        raise "Duplicate arguments for #{self} - [#{dupes.join(',')}]" unless dupes.empty?
        @argSet = Set.new(args)
        updateKey
        self
    end
end

=begin rdoc
The record attribute with the ordered list of arguments.
See RecAttrSet for the unordered set implementation.
=end
class RecAttrList < RecAttr

# Engages the super's parse method via the alias
    alias :recAttrParse :parse

# Creates an instance with the given keyword
    def initialize(keyword); super(keyword) end

# Builds the unique key for the list of arguments on the instance
    def getKey; @args.map { |a| a.to_s }.join(':').to_sym end

=begin rdoc
Parses the instance from the given source preserving the order of arguments, returns self for call chaining.
* Parameters
  * +src+ - an instance of SourceFile
=end
    def parse(src)
        recAttrParse(src)
        updateKey
        self
    end
end

=begin rdoc
Record attrubute "<tt>unique</tt>"
=end
class RecUnique < RecAttrSet

# Creates an instance with the keyword "<tt>unique</tt>"
    def initialize
        #noinspection RubyArgCount
        super(UNIQUE)
    end

=begin rdoc
Attempts to consume the "<tt>unique</tt>" attribute for the given Record from the given source.
* Parameters
  * +source+ - an instance of SourceFile
=end
    def self.consumed?(source, record)
        source.line =~ /^#{UNIQUE}\W.+$/ ? record.addUnique(RecUnique.new.parse(source)) : nil
    end
end

=begin rdoc
Record attrubute "<tt>identity</tt>"
=end
class RecIdentity < RecAttrSet

# Creates an instance with the keyword "<tt>identity</tt>"
    def initialize
        #noinspection RubyArgCount
        super(IDENTITY)
    end

=begin rdoc
Attempts to consume the "<tt>identity</tt>" attribute for the given Record from the given source.
* Parameters
  * +source+ - an instance of SourceFile
=end
    def self.consumed?(source, record)
        source.line =~ /^#{IDENTITY}\W+.+$/ ? record.identity = RecIdentity.new.parse(source) : nil
    end
end

=begin rdoc
Record attrubute "<tt>index</tt>"
=end
class RecIndex < RecAttrList

# Creates an instance with the keyword "<tt>index</tt>"
    def initialize
    #noinspection RubyArgCount
        super(INDEX)
    end

=begin rdoc
Attempts to consume the "<tt>index</tt>" attribute for the given Record from the given source.
* Parameters
  * +source+ - an instance of SourceFile
=end
    def self.consumed?(source, record)
        source.line =~ /^#{INDEX}\W+.+$/ ? record.addIndex(RecIndex.new.parse(source)) : nil
    end
end

=begin rdoc
An array of record level parse token classes, namely RecIdentity, RecIndex, RecUnique
=end
RECORD_LEVEL_TOKENS=[RecIdentity, RecIndex, RecUnique]

end
