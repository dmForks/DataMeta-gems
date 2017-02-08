$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'set'
require 'logger'

module DataMetaDom

# Logger set to WARN, daily rollover and max size 10M
# Feel free to change any of it.
L = Logger.new('dataMetaDom.log', 'daily', 10*1024*1024)
L.level = Logger::WARN

# Keyword: namespace
NAMESPACE = :namespace

# Keyword: include
INCLUDE = :include

# Keyword, data type: string with fixed length
CHAR = :char

# Keyword, data type: string with variable length
STRING = :string

# Keyword, data type: integer
INT = :int

# Keyword, data type: float (real numbers)
FLOAT = :float

# Keyword, data type: boolean
BOOL = :bool

# Keyword, data type: bitset
BITSET = :bitset

# Keyword, data type: URL
URL = :url

# Keyword, data type: map
MAPPING = :mapping

# Keyword, data type: datetime
DATETIME = :datetime

# Keyword, data type: numeric
NUMERIC = :numeric

# Keyword, identity
IDENTITY = :identity

# Keyword, unique
UNIQUE = :unique

# Keyword, matches
MATCHES = :matches

# Keyword, index
INDEX = :index

# Key to a no-namespace
NO_NAMESPACE = ''.to_sym

# Wiki for DataMeta DOM
WIKI = 'http://FIXME'

# HTML tag referencing the WIKI
WIKI_REF_HTML = "<a href='#{WIKI}'>DataMeta</a>"

# Keyword, data type, the RAW type refers to raw data, like a byte array
RAW = :raw

# the reference keyword was not a good idea, too much confusion and dupe functionality
# with the better way, namely referencing an object by name
#REFERENCE=:reference

=begin rdoc
Keyword +doc+, documentation.
=end
DOC = :doc

=begin rdoc
Keyword +ver+, version info.
=end
VER_KW = :ver

# Keyword, data type, enum
ENUM = :enum

# Keyword, end
END_KW = :end

# Keyword, record
RECORD = :record

# Package separator in a namespace.
PACK_SEPARATOR = '.'

# Environment variable for DataMeta DOM library path.
DATAMETA_LIB = 'DATAMETA_LIB'

# for source code generation, 2 spaces
SOURCE_INDENT = ' ' * 2

# Prefix for a required field
REQUIRED_PFX = '+'.to_sym

# Prefix for an optional field
OPTIONAL_PFX = '-'.to_sym

# DataMeta DOM standard types that have a dimension with a scale
SCALE_TYPES = Set.new [NUMERIC]

=begin rdoc
Data Types that must be dimensioned, with a length or with a length and a scale, as
it includes all the SCALE_TYPES too..
=end
DIMMED_TYPES = Set.new ([FLOAT, INT, CHAR, RAW] << SCALE_TYPES.to_a).flatten

# Optionally dimmable types - may have a dim or may have not
OPT_DIMMABLE = Set.new ([STRING]).flatten

# standard types is a superset of dimmensionable types, adding BOOL and DATETIME
STANDARD_TYPES = Set.new(([BOOL, DATETIME, URL] << DIMMED_TYPES.to_a << OPT_DIMMABLE.to_a << SCALE_TYPES.to_a).flatten)

=begin rdoc
Record attribute keywords:
* +identity+
* +unique+
* +index+
=end
REC_ATTR_KEYWORDS = Set.new [IDENTITY, UNIQUE, INDEX]
# Valid first symbol of a DataMeta DOM idenifier such as entity or enum name, field name, enum item.
ID_START = '[A-Za-z_]'

# Valid first symbol for a DataMeta DOM Type
TYPE_START = '[A-Z]'

puts "Standard types: #{STANDARD_TYPES.to_a.map { |k| k.to_s }.sort.join(', ')}" if $DEBUG

# Migration context - for a record
    class MigrCtx
        attr_accessor :rec, :canAuto, :isSkipped
        def initialize(name)
            @rec = name
            @canAuto = true # assume we can automigrate unless encounter problems that would require a HIT
            @isSkipped = false
        end
    end

=begin rdoc
Suffix for the java source files for the implementors of the DataMetaSame interface by all the fields on the class.
=end
    SAME_FULL_SFX = '_DmSameFull'

=begin rdoc
Suffix for the java source files for the implementors of the DataMetaSame interface by identity field(s) on the class.
=end
    SAME_ID_SFX = '_DmSameId'

# +DataMetaSame+ generation style: Full Compare, compare by all the fields defined in the class
    FULL_COMPARE = :full

=begin rdoc
+DataMetaSame+ generation style: Compare by the identity fields only as defined on DataMetaDom::Record
=end
    ID_ONLY_COMPARE = :id

# One indent step for java classes, spaces.
    INDENT = ' ' * 4

# keep in sync with generated classes such as the Java class `CannedRegexUtil` in DataMeta DOM Core/Java etc.
    CANNED_RX = Set.new [:email, :phone]

# holds a custom regex symbol and the variables that use this regex
    class RegExEntry
        attr_reader :r, :vars, :req
# initializes interna variables
        def initialize(regex, var, req)
            @r = regex
            @vars = Set.new [var]
            @req = req
        end
# adds the variable to the instance
        def <<(var)
            @vars << var
        end

        def req?; @req end
    end

# Registry for the regexes so we don't repeat those
    class RegExRoster
        attr_reader :i_to_r, :r_to_i, :canned

        class << self
# Converts the given custom RegEx index to the matching Pattern static final variable name
            def ixToVarName(index)
                "REGEX___#{index}___"
            end
        end

        # sets index to 0, initializes hashes
        def initialize
            @index = 0
            @i_to_r = {}
            @r_to_i = {}
            @canned = {}
        end

        # adds a new regex to the registry
        def register(f)
            var = f.name
            rx = f.regex
            rx = rx[1..-2] if rx.length > 2 && rx.start_with?('/') && rx.end_with?('/')
            k = rx.to_sym
            if CANNED_RX.member?(k)
                if @canned.has_key?(k)
                    @canned[k] << var
                else
                    @canned[k] = RegExEntry.new(k, var, f.isRequired)
                end
            elsif @r_to_i.has_key?(k)
                # this regex is already registered, just add the variable
                @i_to_r[@index] << var
            else
                @index += 1
                @i_to_r[@index] = RegExEntry.new(k, var, f.isRequired)
                @r_to_i[k] = @index
            end
        end

    end

=begin rdoc
With the given full type including the namespace if any and the given namespace (java package, python package etc),
figures out whether the full type has to be reference in full, if it belongs to a different namespace,
or just by the base name if it belongs to the same package.

* Parameters
  * +fullType+ - full data type including the namespace if any
  * +namespace+ - reference namespace.

For example, passed:
    "com.acme.proj.Klass", "com.acme.lib"
will return
    "com.acme.proj.Klass"

but when passed:
    "com.acme.proj.Klass", "com.acme.proj"
will return
    "Klass"

This is to avoid excessive verbosity when referencing entities in the same package.
=end
    def condenseType(fullType, ref_namespace)
        ns, base = DataMetaDom.splitNameSpace(fullType)
        # noinspection RubyNestedTernaryOperatorsInspection
        DataMetaDom.validNs?(ns, base) ? ( ns == ref_namespace ? base : fullType) : fullType
    end

# Migrator implementor name
    def migrClass(base, ver1, ver2); "Migrate_#{base}_v#{ver1.toVarName}_to_v#{ver2.toVarName}" end

=begin rdoc
Builds and returns the Java-style getter name for the given field. This style is used in other platforms such as
Python, for consistency.
=end
    def getterName(f); "get#{DataMetaXtra::Str.capFirst(f.name.to_s)}" end

=begin rdoc
Builds and returns the Java-setter setter name for the given field. This style is used in other platforms such as
Python, for consistency.
=end
    def setterName(f); "set#{DataMetaXtra::Str.capFirst(f.name.to_s)}" end

    module_function :setterName, :getterName

end
