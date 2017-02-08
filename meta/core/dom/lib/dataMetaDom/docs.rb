$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set).each { |r| require r }

module DataMetaDom

# doc target for javadocs
JAVA_DOC_TARGET = :java

# doc target for plaintext
PLAIN_DOC_TARGET = :plain

# All documentation targets
DOC_TARGETS = Set.new [PLAIN_DOC_TARGET, JAVA_DOC_TARGET]

=begin rdoc
Documentation tag

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Doc
=begin rdoc
Documentation target such as PLAIN_DOC_TARGET or JAVA_DOC_TARGET or whatever is added in the future.
May stick with plaintext unless it becomes easy to write in a common markup format and generate
specific doc format from it.

Can be one of the following:
* PLAIN_DOC_TARGET - +plain+
* JAVA_DOC_TARGET - +java+
=end
    attr_reader :target

=begin rdoc
The text of the documentation.
=end
    attr_accessor :text

=begin rdoc
Creates an instance for the given target and given text.
=end
    def initialize(target, text)
        @target = target.to_sym
        #noinspection RubyArgCount
        raise "Unsupported docs target #@target" unless DOC_TARGETS.member?(@target)
        @text = text
    end

=begin rdoc
Parses the documentation from the given source, returns an instance of Doc.

* Parameters:
  * +source+ - an instance of SourceFile
  * +params+ - an array, first member is the target.
=end
    def self.parse(source, params)
        text = ''
        while (line = source.nextLine(true))
            case line
                when /^\s*#{END_KW}\s*$/
                    retVal = Doc.new params[0], text
                    return retVal
                else
                    text << line
            end # case
        end # while line
        raise "Parsing a doc: missing end keyword, source=#{source}"
    end

# Textual for the instance
    def to_s; "Doc-#{target}\n#{text}" end
end # class Doc

# Anything that can have documentation.
class Documentable

=begin rdoc
The hash keyed by the target.
=end
    attr_accessor :docs

#Initializes the instance with an empty hash.
    def initialize; @docs = {} end

# Fetches the instance of Doc by the given key, the target
    def getDoc(key); @docs[key] end

# Adds the document by putting it into the underlying cache with the target key.
    def addDoc(doc)
        @docs[doc.target] = doc
    end

# All the ids, namely the targets of all the documents on this instance.
    def ids; @docs.keys end

# All the instances of the Doc stored on this instance.
    def all; @docs.values end

=begin rdoc
Determines if the given document target is defined on this instance.
* Parameter:
  * +key+ - the target.
=end
    def has?(key) ; @docs.member?(key) end

=begin rdoc
Reinitializes the instance with no docs.
=end
    def clear; @docs[] = {} end

=begin rdoc
Attempts to consume a Doc from the given source, returns true if succeeded.
* Parameters:
  * +source+ - an instance of SourceFile
  * +target+ - the target, the format of the Doc.
=end
    def docConsumed?(source)
        source.line =~ /^\s*#{DOC}\s+(\w+)$/ ? addDoc(Doc.parse(source, [$1])) : nil
    end

end # class Docs

end
