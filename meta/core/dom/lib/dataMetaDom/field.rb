$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'dataMetaDom/docs'
require 'dataMetaDom/ver'

module DataMetaDom

=begin rdoc
A field for a Record, with the full name including namespace if any, required flag, DataType and
default value if any.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Field < VerDoccable

# Aggregation type: Set
    SET = 'set'
# Aggregation type: List
    LIST = 'list'
# Aggregation type: Deque
    DEQUE = 'deque'
# Making a hash/set of 3 members is outright silly, use simple array:
    AGGRS = [SET, LIST, DEQUE]
# Map keyword, that's a different kind of aggregator with 2 types
    MAP = 'map'

=begin rdoc
The name for this field, full name including namespace if any.
=end
    attr_reader :name

=begin rdoc
Required flag, true for a required field, false for an optional one.
=end
    attr_accessor :isRequired

=begin rdoc
Default value for this field if any.
=end
    attr_accessor :default

=begin rdoc
An instance of DataType for the given field. For a Map -- source type
=end
    attr_accessor :dataType

=begin rdoc
Aggregate indicator - one of the constants: SET, LIST, DEQUE. Note it does not include MAP.
=end
    attr_accessor :aggr

=begin rdoc
Target type for a Map
=end
    attr_accessor :trgType

=begin rdoc
+matches+ Regular expression specification if any, for a string
=end
    attr_accessor :regex

    class << self # static members of the class
=begin rdoc
Parses a new field from the given source, adds to the given record with the source info.
* Parameters:
  * +source+ - the instance of SourceFile to parse from
  * +record+ - the instance of the Record to which the newly parsed Field will be added.
=end
    def consume(model, source, record)
        newField = Field.new.parse(model, source)
        if record.docs
            newField.docs = record.docs.clone
            record.docs.clear
        end
        record.addField newField, model, source.snapshot
    end

=begin rdoc
Creates a new field with the the given name, type and required flag. Use to build a Model from the code.
* Parameters:
  * +name+ - full name for the new field, including namespace if any.
  * +dataType+ - an instance of DataType, can use reusable types defined on util.rb.
  * +req+ - the required flag, true for required, see isRequired for details.
=end
        def create(name, dataType, req=false)
            raise ArgumentError, 'Must specify name and type when creating a field from the code' if !name || !dataType
            result = Field.new name
            result.dataType = dataType
            result.isRequired = req
            result
        end
    end

# For readability - determine if the field is aggregated type: LIST, DEQUE, SET
        def aggr?; defined?(@aggr) && @aggr != nil; end
# For readability - determine if the field is a map
        def map?; defined?(@trgType) && @trgType != nil; end
        def set?; defined?(@aggr) && @aggr == SET; end


=begin rdoc
Another way ot create a Field from the code - a constructor, with the given name if any.
See the class method create for more details.
=end
    def initialize(name=nil)
        super()
        @length = nil
        if name
            raise ArgumentError, %<Invlalid field name "#{name}", must be alphanum starting with alpha> unless name =~ /^#{ID_START}\w*$/
            @name = name.to_sym
        end
        @default = nil
    end

=begin rdoc
Parses this field from the given source.
* Parameter:
  * +source+ - an instance of SourceFile
=end
    def parse(model, source)
        @aggr = nil
        @trgType = nil
        src = nil

        if source.line =~ /^\s*([#{REQUIRED_PFX}#{OPTIONAL_PFX}])\s*#{MAP}\{\s*([^\s,]+)\s*,\s*([^\}]+)}(.+)/
           # is it a map{} ?
           ro, srcSpec, trgSpec, tail = $1, $2, $3, $4
           src = %|#{ro}#{srcSpec}#{tail ? tail : ''}|
           @trgType = DataType.parse(source, trgSpec)
           unless STANDARD_TYPES.member?(@trgType.type)
               ns, base = DataMetaDom.splitNameSpace(@trgType.type)
               newNs = nsAdjustment(ns, model.options, source)
               newNsVer = "#{newNs}.#{base}".to_sym
               @trgType.type = newNsVer # adjust the type for the map target type too
           end
#        elsif source.line =~ /^\s*([#{REQUIRED_PFX}#{OPTIONAL_PFX}])\s*(string)\s+(#{ID_START}\w*)\s*(.+)?$/
            # is it a string with no length?
#            req, typeSpec, name, tail = $1, $2, $3, $4
#            src = %|#{req}#{typeSpec}[0] #{name} #{tail}|
        else # is it a list, deque or set?
            AGGRS.each { |a| ## aggregates do not allow matching nor they allow defaults
               if source.line =~ /^\s*([#{REQUIRED_PFX}#{OPTIONAL_PFX}])\s*#{a}\{([^\}]+)\}(.+)/
                   @aggr = a
                   src = %|#{$1}#{$2}#{$3}|
                   break
               end
            }
        end
        r = (src ? src : source.line).scan(/^\s*([#{REQUIRED_PFX}#{OPTIONAL_PFX}])\s*(\S+)\s+(#{ID_START}\w*)\s*(.+)?$/)
        raise "Invalid field spec '#{line}'" unless r
        req, typeSpec, name, tail = r[0]
        defaultSpec = tail =~ /(=\S.+)/ ? $1.strip : nil
        @regex  = tail =~ /#{MATCHES}\s+(.+)/ ? $1.strip : nil # regex can have any symbols, even space, but it starts with a non-space
        #puts "<#{line}> <#{req}>  <#{typeSpec}> <#{dimSpec}> <#@name>"
        raise 'Invalid field spec format' if !name || name.empty? || !req || !typeSpec
        @name = name.to_sym
        @dataType = DataType.parse(source, typeSpec)
        @default = defaultSpec[1..-1] if defaultSpec # skip the = sign
        @isRequired = req.to_sym == REQUIRED_PFX
        self
    end

=begin rdoc
Specification of a default value per the DataMeta DOM syntax or empty string if there is no default value on this field.
=end
    def default_spec; @default ? "=#{@default}" : '' end
# matches specification
    def matches_spec; @regex ? " matches #{@regex}" : '' end

=begin rdoc
Required flag as per the DataMeta DOM syntax, either DataMetaDom::REQUIRED_PFX or DataMetaDom::OPTIONAL_PFX,
the constants defined in the util.rb
=end
    def req_spec; @isRequired ? REQUIRED_PFX : OPTIONAL_PFX end

=begin rdoc
Textual representation of all aspects of the field.
=end
    def to_s; "Field #{@name}(#{req_spec}#{@dataType})#{@default ? '=<' + @default + '>' : ''}" end
end

end
