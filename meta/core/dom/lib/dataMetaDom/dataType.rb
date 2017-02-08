$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set dataMetaDom/util).each { |r| require r }

module DataMetaDom

=begin rdoc
DataMeta DOM Data Type, including the base type, length if any and scale if any.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class DataType

=begin rdoc
Base type; either one of the standard types, see STANDARD_TYPES on the util.rb or fully named custom type
such as a Record, an Enum, a Map, a BitSet.

Use case of changing the type: multiple versions in one VM process.
=end
    attr_accessor :type

=begin rdoc
For those data types that have a dimension, such as length. See DIMMED_TYPES on the util.rb.
=end
    attr_reader :length

=begin rdoc
For those data types that have a scale. See SCALE_TYPES on the util.rb.
=end
    attr_reader :scale

    class << self
# The type must not feature a length
        def mustNotDim(type)
            !DIMMED_TYPES.member?(type) && !OPT_DIMMABLE.member?(type)
        end

# The type must feature a length > 0
        def mustDim(type)
            DIMMED_TYPES.member?(type)
        end

# The type may or may not feature a length
        def canDim(type)
            DIMMED_TYPES.member?(type) || OPT_DIMMABLE.member?(type)
        end

=begin rdoc
Parses type definition from DataMeta DOM source, raising errors if anything is wrong.
Returns a new instance of the DataType.
=end
        def parse(src, textual)
            r = textual.scan(/([\w\.]+)(\[[\d\.]+\])?/)
            raise "Invalid data type spec #{textual}" unless r
            typeSpec, dimSpec = r[0]
            type = typeSpec.to_sym
            raise "The type #{type} can not be dimensioned" if DataType.mustNotDim(type) && dimSpec && !dimSpec.empty?
            raise "The type #{type} must be dimensioned" if DataType.mustDim(type) && (!dimSpec || dimSpec.empty?)
            length = nil; scale = nil
            unless !dimSpec || dimSpec.empty?
                raise "Invalid dimension format '#{dimSpec}'" unless dimSpec.scan(/^\[(\d+)\.?(\d+)?\]$/)
                length = $1.to_i
                scale = $2 ? $2.to_i : nil
            end
            @type = DataMetaDom.fullTypeName(src.namespace, type)
            DataType.new @type, length, scale
        end

    end

=begin rdoc
Creates the instance with the given base type, the length and the scale
=end
    def initialize(t, len=nil, scale=nil)
        raise ArgumentError, "The type #{t} can not have length" if DataType.mustNotDim(t) && len

        raise ArgumentError, "The type #{type} must have length > 0, but \"#{len}\" specified" \
          if DataType.mustDim(t) && (!len || len < 1)

        @type = t.to_sym
        @length = len
        @scale = scale
    end

=begin rdoc
Builds a length (dimension) and scale specification for this type according to the DataMeta DOM syntax.
If the type does not have a dimension (no length, no scale), returns empty string.
=end
    def length_spec; @length && @length != 0 ? "[#{@length}" + (@scale ? '.' + @scale.to_s : '') + ']' : '' end

# Textual representation of this isntance, includes the type spec with the length spec.
    def to_s; "#{@type}#{length_spec}" end
end

# Reusable type - Integer of the length 1, aka Java's +byte+.
INT1 = DataType.new(INT, 1)
# Reusable type - Integer of the length 2, aka Java's +short+.
INT2 = DataType.new(INT, 2)
# Reusable type - Integer of the length 4, aka Java's +int+.
INT4 = DataType.new(INT, 4)
# Reusable type - Integer of the length 8, aka Java's +long+.
INT8 = DataType.new(INT, 8)
# Reusable type - Float (Real number) of the length 4, aka Java's +float+.
FLOAT4 = DataType.new(FLOAT, 4)
# Reusable type - Float (Real number) of the length 8, aka Java's +double+.
FLOAT8 = DataType.new(FLOAT, 8)
# Reusable type - DATETIME, in Java projected into <tt>java.time.ZonedDateTime</tt>.
DTTM_TYPE = DataType.new(DATETIME)
# Reusable type - URL, in Java projected into <tt>java.net.URL</tt>.
URL_TYPE = DataType.new(URL)

end
