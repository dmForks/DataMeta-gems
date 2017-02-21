$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'set'
require 'dataMetaDom/util'
require 'dataMetaDom/recAttr'
require 'dataMetaDom/dataType'
require 'dataMetaDom/field'
require 'dataMetaDom/docs'
require 'dataMetaDom/enum'
require 'dataMetaDom/record'
require 'dataMetaDom/ref'
require 'dataMetaDom/sourceFile'
require 'date'
require 'dataMetaXtra'
require 'dataMetaDom/sources'
require 'dataMetaDom/model'

=begin rdoc

DataMeta DOM infrastructure root.

For command line details either check the new method's source or the README.rdoc file, the usage section.

=end
module DataMetaDom

# Current version
VERSION = '1.0.2'

=begin rdoc
Quick and dirty turning a Windows path into a path of the platform on which this script is running.
Assumes that backslash is never used as a part of a directory name, pretty safe assumption.
=end
def uniPath(source)
    source.gsub(/\\/, File::SEPARATOR)
end

=begin rdoc
Returns an array of the namespace and the base, first element nil if no namespace
both elements nil if not a proper namespace.
@param [String] source source text to split
@return [Array] array of +String+, the namespace and the base
=end
def splitNameSpace(source)
    #noinspection RubyNestedTernaryOperatorsInspection
    source =~ /(\w[\w\.]*)\.(#{TYPE_START}\w*)/ ? [($1.empty? ? nil : $1), $2] :
            (source =~ /(#{TYPE_START}\w*)/ ? [nil, source] : [nil, nil])
end

# adjust the namespace if required
def nsAdjustment(namespace, options, src)
    src && options[:autoNsVer] ? "#{namespace}.v#{src.ver.full.toVarName}" : namespace
end

=begin rdoc
Combines the namespace with the base name: if the namespace is empty or +nil+, returns the base name as a symbol,
otherwise returns namespace.base
@param [String] namespace the namespace part
@param [String] base the base name of the entity
@return [String] base and namespace properly combined into full name specification
=end
def combineNsBase(namespace, base)
    namespace && !namespace.empty? ? "#{namespace}.#{base}".to_sym : base.to_sym
end

=begin rdoc
Given the namespace and the base, returns true if the namespace is a valid one.
@param [String] namespace the namespace part
@param [String] base the base name of the entity
@return [Boolean] true if the given namespace passes simple smell check with the given base
=end
def validNs?(namespace, base)
    namespace && !namespace.empty? && namespace.to_sym != base
end

=begin rdoc
if name is a standard type, return it.
if name is a fully qualified namespaced name, return it
otherwise, combine the namespace provided with the base to return the full name
=end
def fullTypeName(namespace, name)
    #noinspection RubyUnusedLocalVariable
    ns, _ = splitNameSpace(name.to_s) # if it is already a full namespaced name or a standard type, return original
    validNs?(ns, name) || STANDARD_TYPES.member?(name) ? name.to_sym : "#{combineNsBase(namespace, name)}".to_sym
end

# Returns qualified name for the given namespace: strips the namespace if the namespace is the same, or keep it
def qualName(namespace, name)
    ns, b = splitNameSpace(name.to_s)
    !STANDARD_TYPES.member?(name.to_sym) && (!validNs?(ns, b) || ns == namespace) ? b : name
end

=begin rdoc
Simplest diminfo to be reused wherever no other aspect of a datatype is needed

@!attribute [r] len
    @return [Fixnum] the Length part of the dimension info
@!attribute [r] scale
    @return [Fixnum] the Scale part of the dimension info

=end
class DimInfo

    attr_reader :len, :scale

# Creates an instance with the given parameters
    def initialize(len, scale); @len = len; @scale = scale end

# Textual representation of this instance, length.scale
    def to_s; "#{@len}.#{@scale}" end

# Convenience constant - NIL dimension to use in the types that are not dimensioned.
    NIL=DimInfo.new(nil, nil)
end

=begin rdoc
# Parses parenthesized dimension info such as (18, 2) or just (18)

Returns DimInfo::NIL if the dimSpec is +nil+ or the DimInfo instance as specified
=end
def getParenDimInfo(dimSpec)
    return DimInfo::NIL unless dimSpec
    result = dimSpec =~ /^\s*\(\s*(\d+)\s*(?:,\s*(\d+))?\s*\)\s*$/
    raise "Invalid dimension specification: '#{dimSpec}'" unless result
    DimInfo.new($1.to_i, $2.to_i)
end

=begin rdoc
Adds options to help and version from the first argument
And shortcuts to showing the help screen if the ARGV is empty.
The options for help are either <tt>--help</tt> or </tt>-h</tt>.
The option for show version and exit is either <tt>--version</tt> or <tt>-v</tt>.
=end
def helpAndVerFirstArg
    raise Trollop::HelpNeeded if ARGV.empty? || ARGV[0] == '--help' || ARGV[0] == '-h' # show help screen
    raise Trollop::VersionNeeded if ARGV[0] == '--version' || ARGV[0].downcase == '-v' # show version screen
end

module_function :combineNsBase, :splitNameSpace, :uniPath, :validNs?, :getParenDimInfo,
                :helpAndVerFirstArg, :fullTypeName, :nsAdjustment
end
