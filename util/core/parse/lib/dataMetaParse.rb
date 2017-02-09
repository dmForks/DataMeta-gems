$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'treetop'
=begin rdoc
Grammar parsing commons for the dataMeta Project.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
module DataMetaParse
    # Current version
    VERSION = '1.0.0'

=begin rdoc
Parsing error, RuntimeError augmented with report feature

=end
    class Err < RuntimeError
        attr_reader :source, :parser
=begin rdoc
Constructor, constructs also the error message passed to the super.

@param [String] source the next have been parsed to get this error
@param [Object] parser Treetop compiled parser whichever class it is. It may be +Treetop::Runtime::CompiledParser+
=end
        def initialize(source, parser)
            @source, @parser = source, parser
            parser.failure_reason =~ /^(Expected .+) after/m
            reason = $1 || 'REASONLESS'
            # replace newlines with <EOL> to make them stand out
            super %Q<ERROR at index #{parser.index}
#{reason.gsub("\n", '<EOL>')}:
#{source.lines.to_a[parser.failure_line - 1]}
#{'~' * (parser.failure_column - 1)}^
>
        end
    end
=begin rdoc
Loads the base rules from +dataMetaParse/basic.treetop+
=end
    def loadBaseRulz
        Treetop.load("#{File.dirname(__FILE__)}/dataMetaParse/basic")
    end

=begin rdoc
Parse with error handling, convenience shortcut to the content of this method.

@param [Object] parser Treetop compiled parser whichever class it is. It may be +Treetop::Runtime::CompiledParser+
@param [String] source the data to parse with the given parser
@return [Object] either the AST, likely as +Treetop::Runtime::SyntaxNode+ if the parsing was successful or {Err} if it was not
    or +nil+ if there is no match. It's not very consistent of when you get an Err or when you get a +nil+, it's
    not exact science. One way to get a +nil+ is to cause mismatch in the very first token.
=end
    def parse(parser, source)
        parser.parse(source) || ( parser.failure_reason ? Err.new(source, parser) : nil)
    end

    module_function :loadBaseRulz, :parse
end
