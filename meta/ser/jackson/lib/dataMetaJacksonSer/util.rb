$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'set'
require 'logger'

module DataMetaJacksonSer

=begin rdoc
A holder for a read renderer and a write renderer, those come in pairs that have to be consistent so the
data is read and written uniformly.
=end
    class RwHolder
=begin rdoc
Read renderer.
=end
        attr_reader :r
=begin rdoc
Write renderer.
=end
        attr_reader :w
=begin rdoc
Creates a new HDFS Reade and Write renderers pair.
=end
        def initialize(readRenderer, writeRenderer); @r = readRenderer; @w = writeRenderer end
    end

=begin rdoc
Rendering context with rendering-related properties and settings.
=end
    class RendCtx

=begin rdoc
DataMeta DOM Model on the context.
=end
        attr_accessor :model
=begin rdoc
Record currently worked on.
=end
        attr_accessor :rec

=begin rdoc
Set of imports if any, each as symbol.
=end
        attr_accessor :imps

=begin rdoc
Java package.
=end
        attr_accessor :pckg
=begin rdoc
Base name of the type, without a namespace.
=end
        attr_accessor :baseName
=begin rdoc
The data type of the entity on the context.
=end
        attr_accessor :refType
=begin rdoc
Field currently on the context.
=end
        attr_reader :fld

=begin rdoc
Creates a new context.
=end
        def initialize; @imps = Set.new end

=begin rdoc
Setter for the field on the context, the field currently worked on.
=end
        def fld=(val); @fld = val end

=begin rdoc
Initialize the context with the model, the record, the package and the basename.
Returns self for call chaining.
=end
        def init(model, rec, pckg, baseName); @model = model; @rec = rec; @pckg = pckg; @baseName = baseName; self end

=begin rdoc
Add an import to the context, returns self for call chaining.
=end
        def <<(import)
            @imps << import.to_sym if import
            self
        end

=begin rdoc
Formats imports into Java source, sorted.
=end
        def importsText
            @imps.to_a.map{|k| "import #{k};"}.sort.join("\n")
        end

=begin rdoc
Determines if the refType is a DataMetaDom::Mapping.
=end
        def isMapping
            @refType.kind_of?(DataMetaDom::Mapping) && !@refType.kind_of?(DataMetaDom::BitSet)
        end

# Effective field type
        def fType
            isMapping ? @refType.fromT : @fld.dataType
        end

# Readwrap
        def rw
            isMapping ? lambda{|t| "new #{condenseType(@fld.dataType.type, self)}(#{t})"} : lambda{|t| t}
        end

=begin rdoc
Getter name for the current field, if the type is Mapping, includes <tt>.getKey()</tt> too.
=end
        def valGetter
            "#{DataMetaDom.getterName(@fld)}" + ( isMapping ? '.getKey' : '')
        end
    end # RendCtx

=begin rdoc
Builds a class name for a InOutable.
=end
    def jsonableClassName(baseName); "#{baseName}_JSONable" end

    def mapsNotSupported(fld)
        raise ArgumentError, "Field #{fld.name}: maps are not currently supported on JSON serialization layer"
    end

    def aggrNotSupported(fld, forWhat)
        raise ArgumentError, "Field #{fld.name}: aggregate types are not supported for #{forWhat} on JSON serialization layer"
    end

    module_function :jsonableClassName, :mapsNotSupported, :aggrNotSupported
end
