$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'dataMetaDom/help'
require 'dataMetaDom/field'
require 'dataMetaDom/util'

module DataMetaDom

=begin rdoc
Definition for generating Scala artifacts such as case classes and everything related that depends on Scala distro only
witout any other dependencies.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
module ScalaLexer
    include DataMetaDom

=begin rdoc
Scala Data Meta export subpackage, to distinguish between other platforms. Can not make it just ".scala" because if
someone imports all the data model classes with underscore, they may pick up the "scala" subpackage too.

In which case, they will have trouble importing anything from the Scala core by "scala.*",
that violates the principle of "Least Astonishment", they may dink around till they find out that
they will have to use the _root_ package to access the Scala core's "scala", not the exported DataMeta "scala".
=end
    SCALA_SUBPACKAGE = 'scadm'

=begin rdoc
Renderer for the String type.
=end
    TEXTUAL_TYPER = lambda{|t| 'String'}
=begin rdoc
Maps DataMeta DOM datatypes to the matching Scala classes, for those that need to be imported.
The Scala source generator will import these if they are used in the class.
=end
    SCALA_IMPORTS = {
            DATETIME => 'java.time.ZonedDateTime',
            NUMERIC => 'scala.math.BigDecimal'
    }

=begin rdoc
DataMeta DOM aggregated field type spec mapped to matching Scala Case class:
=end
    AGGR_CLASSES = {
            Field::SET => 'scala.collection.Seq', # for Case classes, if the identity is different that full set of fields, Set makes no sense
            # which is a majority of the cases. Wait for full implementation and switch to scala.collection.mutable.Set
            Field::LIST => 'scala.collection.immutable.List',
            Field::DEQUE => 'scala.collection.Seq',
    }

=begin rdoc
A map from DataMeta DOM standard types to the lambdas that render correspondent Scala types per Scala syntax.

We used to render the primitives for the required types but the Verifiable interface made it impractical.
=end
    SCALA_TYPES = {
            DataMetaDom::INT => lambda{ |t|
                len = t.length
                case
                    when len <= 4; 'Int'
                    when len <=8; 'Long'
                    else; raise "Invalid integer length #{len}"
                end
            },
            STRING => TEXTUAL_TYPER,
            DATETIME => lambda{|t| 'ZonedDateTime'},
            BOOL => lambda{|t| 'Boolean'}, # req ? 'boolean' : 'Boolean'},
            CHAR => TEXTUAL_TYPER,
            FLOAT => lambda{|t|
                len = t.length
                case
                    when len <= 4; 'Float' # req ? 'float' : 'Float'
                    when len <=8; 'Double' #req ? 'double' : 'Double'
                    else; raise "Invalid float length #{len}"
                end
            },
            RAW => lambda{|t| 'Array[Byte]'},
            URL => lambda{|t| URL_CLASS},
            NUMERIC => lambda{|t| 'BigDecimal'}
    }

=begin rdoc
Maximum size of a Mapping (Map), rather aribtrary choice, not backed by any big idea.
=end
    MAX_MAPPING_SIZE = 10000

    class << self
=begin rdoc
   Figures out type adjusted for aggregates and maps.
=end
        def aggrType(aggr, trg, rawType, scalaPackage)
            if aggr
                k = rawType.to_sym
                subType = rawType # PRIMS_TO_WRAP.has_key?(k) ? PRIMS_TO_WRAP[k] :
                "#{aggr}[#{subType}]"
            elsif trg
                k = rawType.to_sym
                srcType = rawType
                typeRenderer = SCALA_TYPES[trg.type]
                rawTrg = typeRenderer ? typeRenderer.call(trg) : self.condenseType(self.scalaNs(trg.type), scalaPackage)
                k = rawTrg.to_sym
                trgType = rawTrg
                "Map[#{srcType}, #{trgType}]"
            else
                rawType
            end
        end

    end

    def self.condenseType(fullType, ref_namespace)
        ns, base = DataMetaDom.splitNameSpace(fullType)
        ns = self.scalaNs(ns)
        # noinspection RubyNestedTernaryOperatorsInspection
        DataMetaDom.validNs?(ns, base) ? ( ns == ref_namespace ? base : fullType) : fullType
    end
    
# Unaggregated Scala type
    def self.unaggrScalaType(dt, scalaPackage)
        typeRenderer = SCALA_TYPES[dt.type]
        typeRenderer ? typeRenderer.call(dt) : self.condenseType(self.scalaNs(dt.type), scalaPackage)
    end

# aggregated Scala type
    def self.aggrScalaType(f, scalaPackage)
        rawType = self.unaggrScalaType(f.dataType, scalaPackage)
        aggr = f.aggr? ? DataMetaDom.splitNameSpace(AGGR_CLASSES[f.aggr])[1] : nil
        ScalaLexer.aggrType(aggr, f.trgType, rawType, scalaPackage)
    end
=begin rdoc
Given the property +docs+ of Documentable, return the SCALA_DOC_TARGET if it is present,
PLAIN_DOC_TARGET otherwise. Returns empty string if the argument is nil.
=end
    def scalaDocs(docs)
        return '' unless docs
        case
            when docs[PLAIN_DOC_TARGET]
                docs[PLAIN_DOC_TARGET].text
            else
                ''
        end
    end
=begin rdoc
Scala Class ScalaDoc text with the Wiki reference.
=end
    def classScalaDoc(docs)
        return  <<CLASS_SCALADOC
/**
#{ScalaLexer.scalaDocs(docs)}
 */
CLASS_SCALADOC
    end

=begin rdoc
Scala Enum class-level ScalaDoc text with the Wiki reference.
=end
    def enumScalaDoc(docs)
        return <<ENUM_SCALADOC
/**
#{ScalaLexer.scalaDocs(docs)}
 */
ENUM_SCALADOC
    end

=begin rdoc
For the given DataMeta DOM data type and the isRequired flag, builds and returns the matching Scala data type declaration.
For standard types, uses the SCALA_TYPES map
=end
    def getScalaType(dmDomType)
        typeRenderer = SCALA_TYPES[dmDomType.type]
        typeRenderer ? typeRenderer.call(dmDomType) : dmDomType.type
    end

=begin rdoc
Generates Scala source code, the Scala class for a DataMeta DOM Record

Parameters:
* +model+ - the source model to export from
* +out+ - open output file to write the result to.
* +record+ - instance of DataMetaDom::Record to export
* +scalaPackage+ - Scala package to export to
* +baseName+ - the name of the class to generate.
=end
    def self.genEntity(model, out, record, scalaPackage)
        baseName = record.baseName
        fields = record.fields
        out.puts <<ENTITY_CLASS_HEADER

#{record.docs.empty? ? '' : ScalaLexer.classScalaDoc(record.docs)}case class #{baseName} (
  #{fields.keys.map { |k|
            f = fields[k]
            typeDef = self.aggrScalaType(f, scalaPackage)
            "  `#{f.name}`: #{typeDef}#{model.enums.keys.member?(f.dataType.type) ? '.Value' : ''}"
        }.join(",\n  ")
  }
)
ENTITY_CLASS_HEADER
    end

=begin rdoc
Generates Scala source code for the worded enum, DataMeta DOM keyword "<tt>enum</tt>".
=end
    def self.genEnumWorded(out, enum)
        values = enum.keys.map{|k| enum[k]} # sort by ordinals to preserve the order
        _, base, _ = assertNamespace(enum.name)
        out.puts %<

#{enum.docs.empty? ? '' : enumScalaDoc(enum.docs)}object #{base} extends Enumeration {
  type #{base} = Value
  val #{values.map{|v| "`#{v}`"}.join(', ')} = Value
}
>
    end

# Distinguish JVM classes by the platform, unless it's Java
    def self.scalaNs(ns)
        "#{ns}.#{SCALA_SUBPACKAGE}"
    end

=begin rdoc
Extracts 3 pieces of information from the given full name:
* The namespace if any, i.e. Scala package, empty string if none
* The base name for the type, without the namespace
* Scala package's relative path, the dots replaced by the file separator.

Returns an array of these pieces of info in this exact order as described here.
=end
    def assertNamespace(name)
        ns, base = DataMetaDom.splitNameSpace(name)
        scalaPackage = DataMetaDom.validNs?(ns, base) ? ns : ''
        packagePath = scalaPackage.empty? ? '' : scalaPackage.gsub('.', File::SEPARATOR)

        [scalaPackage, base, packagePath]
    end
=begin rdoc
Generates scala sources for the model, the POJOs.
* Parameters
  * +parser+ - instance of Model
  * +outRoot+ - output directory
=end
    def genCaseClasses(model, outRoot)
        firstRec = model.records.values.first
        raise ArgumentError, "No records defined in the model #{model.sources.masterPath}" unless firstRec

        scalaPackage, base, packagePath = assertNamespace(firstRec.name)
        scalaPackage = self.scalaNs(scalaPackage)
        destDir = File.join(outRoot, packagePath, SCALA_SUBPACKAGE) # keep this in sync with scalaNs
        FileUtils.mkdir_p destDir
        out = File.open(File.join(destDir, 'Model.scala'), 'wb')
        begin
            out.puts %<package #{scalaPackage}

import java.time.ZonedDateTime
import scala.math.BigDecimal
import scala.collection.immutable.Set
import scala.collection.immutable.List
import scala.collection.Seq

/**
 * This content is generated by DataMeta, do not edit manually!
 */
>

            (model.enums.values + model.records.values).each {|e|
                case
                    when e.kind_of?(DataMetaDom::Record)
                        self.genEntity model, out, e, scalaPackage
                    when e.kind_of?(DataMetaDom::Mappings)
                        raise ArgumentError, "For name #{e.name}: Mappings can not be generated to a case class"
                    when e.kind_of?(DataMetaDom::Enum)
                        self.genEnumWorded out, e
                    when e.kind_of?(DataMetaDom::BitSet)
                        raise ArgumentError, "For name #{e.name}: BitsSets can not be generated to a case class"
                    else
                        raise "Unsupported Entity: #{e.inspect}"
                end
            }
        ensure
            out.close
        end
    end

    module_function :genCaseClasses

end
end

