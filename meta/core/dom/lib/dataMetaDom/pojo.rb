$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'set'
require 'fileutils'
require 'dataMetaDom/help'
require 'dataMetaDom/field'
require 'dataMetaDom/util'
require 'erb'
require 'ostruct'

module DataMetaDom

=begin rdoc
Definition for generating Plain Old Java Objects (POJOs) and everything related that depends on JDK only
witout any other dependencies.

TODO this isn't a bad way, but beter use templating next time such as {ERB}[http://ruby-doc.org/stdlib-1.9.3/libdoc/erb/rdoc/ERB.html].

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
module PojoLexer
    include DataMetaDom

=begin rdoc
Maps DataMeta DOM datatypes to the matching Java classes, for those that need to be imported.
The Java source generator will import these if they are used in the class.
=end
    JAVA_IMPORTS = {
            DATETIME => 'java.time.ZonedDateTime',
            NUMERIC => 'java.math.BigDecimal'
    }

=begin rdoc
DataMeta DOM aggregated field type spec mapped to matching Java class:
=end
    AGGR_CLASSES = {
           Field::SET => 'java.util.Set',
           Field::LIST => 'java.util.List',
           Field::DEQUE => 'java.util.LinkedList',
    }

# Augment the class with Java specifics
    class JavaRegExRoster < RegExRoster

# converts the registry to the java declarations for the class
        def to_patterns
            i_to_r.keys.map { |ix|
               r = i_to_r[ix]
               rx = r.r.to_s
               %<#{INDENT}private static final java.util.regex.Pattern #{RegExRoster.ixToVarName(ix)} = // #{r.vars.to_a.sort.join(', ')}
#{INDENT*2}java.util.regex.Pattern.compile(#{rx.inspect});>
            }.join("\n\n")
        end

# converts the registry to the verification code for the verify() method
        def to_verifications
            result = (canned.keys.map { |r|
                r = canned[r]
                vs = r.vars.to_a.sort
                vs.map { |v|
                    rx = r.r.to_s
                    %<#{INDENT*2}if(#{r.req? ? '' : "#{v} != null && "}!getCannedRegEx(#{rx.inspect}).matcher(#{v}).matches())
#{INDENT*3}throw new VerificationException("Variable \\"#{v}\\" == {{" + #{v} + "}} didn't match canned expression \\"#{rx}\\"" );>
                }
            }).flatten
            (result << i_to_r.keys.map { |ix|
                r = i_to_r[ix]
                vs = r.vars.to_a.sort
                rv = RegExRoster.ixToVarName(ix)
                vs.map { |v|
                   %<#{INDENT*2}if(#{r.req? ? '' : "#{v} != null && "}!#{rv}.matcher(#{v}).matches())
#{INDENT*3}throw new VerificationException("Variable \\"#{v}\\" == {{" + #{v} + "}} didn't match custom expression {{" + #{rv} + "}}");>
                }
            }).flatten
            result.join("\n")

        end
    end

=begin rdoc
Special import for special case -- the map
=end
    MAP_IMPORT = 'java.util.Map'

# URL data type projection into Java
    URL_CLASS = 'java.net.URL'

=begin rdoc
Field types for which Java primitivs can be used along with == equality.

Note that CHAR is not primitivable, we do not expect any
single character fields in our metadata that should be treated differently than multichar fields.

Deprecated. With the advent of the Verifiable interface, we must have all objects, no primitives.
=end
    PRIMITIVABLE_TYPES = Set.new # [DataMetaDom::INT, BOOL, FLOAT]

=begin
Primitives that need to be converted to wrappers for aggregate types.
=end
    PRIMS_TO_WRAP = {
           :int => 'Integer',
           :long => 'Long',
           :boolean => 'Boolean',
           :float => 'Float',
           :double => 'Double',
    }

    # Methods to fetch primitives values:
    def primValMethod(dt)
        case dt.type
            when INT
                dt.length < 5 ? 'intValue' : 'longValue'
            when FLOAT
                dt.length < 5 ? 'floatValue' : 'doubleValue'
            else
                raise ArgumentError, %<Can't determine primitive value method for the data type: #{dt}>
        end
    end
=begin rdoc
Wraps type into <tt>com.google.common.base.Optional<></tt> if it is required
<tt>
    def wrapOpt(isReq, t); isReq ? t : "Optional<#{t}>" end
</tt>

After a bit of thinking, decided not to employ the Optional idiom by Guava then of the JDK 8 for the following reasons:
* the pros don't look a clear winner vs the cons
  * if an optional field is made non-optional, lots of refactoring would be needed that is hard to automate
  * Java developers are used to deal with nulls, not so with Optionals
  * it requires dragging another dependency - Guava with all the generated files.
  * wrapping objects into Optional would create a lot of extra objects in the heap
    potentially with long lifespan
=end
    def wrapOpt(isReq, t); t end # - left the work done just in case

=begin rdoc
Renderer for the String type.
=end
    TEXTUAL_TYPER = lambda{|t| 'String'}

=begin rdoc
A map from DataMeta DOM standard types to the lambdas that render correspondent Java types per Java syntax.

We used to render the primitives for the required types but the Verifiable interface made it impractical.
=end
    JAVA_TYPES = {
            DataMetaDom::INT => lambda{ |t|
              len = t.length
              case
                when len <= 4; 'Integer' #req ? 'int' : 'Integer'
                when len <=8; 'Long' # req ? 'long' : 'Long'
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
          RAW => lambda{|t| 'byte[]'},
          URL => lambda{|t| URL_CLASS},
          NUMERIC => lambda{|t| 'BigDecimal'}
    }

=begin rdoc
A hash from a character sequences to their Java escapes. Used by escapeJava method which is deprecated, see the docs,
there are better ways to escape Java string in Ruby.
=end
    JAVA_ESCAPE_HASH = { '\\'.to_sym => '\\\\',
       "\n".to_sym => '\\n',
       '"'.to_sym => '\\"',
       "\t".to_sym => '\\t',
    }

=begin rdoc
Maximum size of a Mapping (Map), rather aribtrary choice, not backed by any big idea.
=end
  MAX_MAPPING_SIZE = 10000

    class << self
=begin rdoc
   Figures out type adjusted for aggregates and maps.
=end
        def aggrType(aggr, trg, rawType, javaPackage)
            if aggr
                k = rawType.to_sym
                subType = PRIMS_TO_WRAP.has_key?(k) ? PRIMS_TO_WRAP[k] : rawType
                "#{aggr}<#{subType}>"
            elsif trg
                k = rawType.to_sym
                srcType = PRIMS_TO_WRAP.has_key?(k) ? PRIMS_TO_WRAP[k] : rawType
                typeRenderer = JAVA_TYPES[trg.type]
                rawTrg = typeRenderer ? typeRenderer.call(trg) : DataMetaDom.condenseType(trg.type, javaPackage)
                k = rawTrg.to_sym
                trgType = PRIMS_TO_WRAP.has_key?(k) ? PRIMS_TO_WRAP[k] : rawTrg
                "Map<#{srcType}, #{trgType}>"
            else
                rawType
            end
        end

    end

=begin rdoc
Given the property +docs+ of Documentable, return the JAVA_DOC_TARGET if it is present,
PLAIN_DOC_TARGET otherwise. Returns empty string if the argument is nil.
=end
    def javaDocs(docs)
        return '' unless docs
        case
            when docs[JAVA_DOC_TARGET]
                docs[JAVA_DOC_TARGET].text
            when docs[PLAIN_DOC_TARGET]
                docs[PLAIN_DOC_TARGET].text
            else
                ''
        end
    end
=begin rdoc
Java Class JavaDoc text with the Wiki reference.
=end
    def classJavaDoc(docs)
      return  <<CLASS_JAVADOC
/**
#{PojoLexer.javaDocs(docs)}
 * This class is generated by
 * #{WIKI_REF_HTML}.
 */
CLASS_JAVADOC
    end

=begin rdoc
Java Enum class-level JavaDoc text with the Wiki reference.
=end
  def enumJavaDoc(docs)
      return <<ENUM_JAVADOC
/**
#{PojoLexer.javaDocs(docs)}
 * This enum is generated by
 * #{WIKI_REF_HTML}.
 */
ENUM_JAVADOC
  end

=begin rdoc
For the given DataMeta DOM data type and the isRequired flag, builds and returns the matching Java data type declaration.
For standard types, uses the JAVA_TYPES map
=end
    def getJavaType(dmDomType)
      typeRenderer = JAVA_TYPES[dmDomType.type]
      typeRenderer ? typeRenderer.call(dmDomType) : dmDomType.type
    end

=begin rdoc
Renders the value for the given DataType according to Java syntax, for all standard data types.
See STANDARD_TYPES.
=end
    def getJavaVal(dataType, val)
      case
        when dataType.type == DATETIME
          %Q< java.time.ZonedDateTime.from(java.time.format.DateTimeFormatter.ISO_DATE_TIME.parse("#{val.to_s}")) >
        when dataType.type == NUMERIC
          %Q< new BigDecimal(#{val.inspect}) >
        when val.kind_of?(Symbol)
          val.to_s.inspect
        when dataType.type == FLOAT && dataType.length <= 4
          "#{val.inspect}F"
        when dataType.type == INT && dataType.length > 4
          "#{val.inspect}L"
        when dataType.type == URL
          %Q< new java.net.URL(#{val.inspect}) >
        else
          val.inspect
      end
    end

=begin rdoc
Used to escape the given string according to the Java syntax, now *deprecated*, use Ruby Object.inspect
or the getJavaVal method.
=end
    def escapeJava(what)
      result = ''
      what.each_char { |c|
        replacement = JAVA_ESCAPE_HASH[c.to_sym]
        result << (  replacement ?  replacement : c )
      }
      result
    end

=begin rdoc
Builds Java imports for the given fields if any, per JAVA_IMPORTS.
Returns the text of imports to insert straight into the Java source file
=end
    def javaImports(fields)
        imports = Set.new
        fields.each { |f|
              importable = JAVA_IMPORTS[f.dataType.type]
              imports << importable.to_sym if importable
              if f.aggr?
                  imports << AGGR_CLASSES[f.aggr].to_sym
              elsif f.map?
                  imports << MAP_IMPORT.to_sym
                  srcImport = JAVA_IMPORTS[f.trgType.type]
                  imports << srcImport.to_sym if srcImport
              end
        }
        imports

        # remnant of the Optional effort for non-required fields
        #hasOpt = fields.values.map{|f| !f.isRequired }.reduce(:|) # true if there is at least one optional field
        #imports << 'com.google.common.base.Optional' << 'static com.google.common.base.Optional.fromNullable' if hasOpt
    end

# Converts an import set to the matching Java source snippet.
    def importSetToSrc(importSet)
        importSet.to_a.map{|k| "import #{k};"}.sort.join("\n") + "\n"
    end

=begin rdoc
Generates Java source code, the Java class for a DataMeta DOM Record

Parameters:
* +model+ - the source model to export from
* +out+ - open output file to write the result to.
* +record+ - instance of DataMetaDom::Record to export
* +javaPackage+ - Java package to export to
* +baseName+ - the name of the class to generate.
=end
    def genEntity(model, out, record, javaPackage, baseName)
      fields = record.fields
      # scan for imports needed

      out.puts <<ENTITY_CLASS_HEADER
package #{javaPackage};
#{importSetToSrc(javaImports fields.values)}
import org.ebay.datameta.dom.Verifiable;
import java.util.Objects;
import java.util.StringJoiner;
import org.ebay.datameta.dom.VerificationException;
import org.ebay.datameta.util.jdk.SemanticVersion;
import static org.ebay.datameta.dom.CannedRegexUtil.getCannedRegEx;

#{PojoLexer.classJavaDoc(record.docs)}public class #{baseName} implements Verifiable {

ENTITY_CLASS_HEADER
if record.ver
    out.puts %Q<#{INDENT}public static final SemanticVersion VERSION = SemanticVersion.parse("#{record.ver.full}");

>
end
      fieldDeclarations = ''
      gettersSetters = ''
      eqHashFields = record.identity ? record.identity.args : fields.keys.sort
      reqFields = fields.values.select{|f| f.isRequired }.map{|f| f.name}
      rxRoster = JavaRegExRoster.new
      fieldVerifications = ''
      fields.each_key { |k|
        f = fields[k]
        dt = f.dataType
        rxRoster.register(f) if f.regex

        typeDef = aggrJavaType(f, javaPackage)

        if f.trgType # Maps: if either the key or the value is verifiable, do it
            mainVf = model.records[dt.type] # main data type is verifiable
            trgVf = model.records[f.trgType.type]  # target type is verifiable
            if mainVf || trgVf
                fieldVerifications << "#{INDENT*2}#{!f.isRequired ? "if(#{f.name} != null) " : '' }#{f.name}.forEach((k,v) -> {#{mainVf ? 'k.verify();' : ''} #{trgVf ? 'v.verify();' : ''}});\n"
            end
        end

        if model.records[dt.type] && !f.trgType # maps handled separately
            fieldVerifications << "#{INDENT*2}#{!f.isRequired ? "if(#{f.name} != null) " : '' }#{f.name}#{f.aggr ? '.forEach(Verifiable::verify)' : '.verify()'};\n"
            # the Verifiable::verify method reference works just fine, tested it: Java correctly calls the method on the object
        end

        fieldDeclarations << "\n#{INDENT}private #{wrapOpt(f.isRequired, typeDef)} #{f.name};"
        if f.isRequired
            gettersSetters << <<CHECKING_SETTER
#{INDENT}public void #{DataMetaDom.setterName(f)}(final #{typeDef} newValue) {
#{INDENT*2}if(newValue == null) throw new IllegalArgumentException(
#{INDENT*4}"NULL passed to the setter of the required field '#{f.name}' on the class #{record.name}.");
#{INDENT*2}this.#{f.name} = newValue;
#{INDENT}}
CHECKING_SETTER
        else # not required, can not be primitive - wrap into Optional<>
          gettersSetters << "\n#{INDENT}public void #{DataMetaDom.setterName(f)}(final #{wrapOpt(f.isRequired, typeDef)} newValue) {this.#{f.name} = newValue; }\n"
        end
        if f.docs.empty?
            gettersSetters << "\n"
        else
            gettersSetters << <<FIELD_JAVADOC
#{INDENT}/**
#{PojoLexer.javaDocs f.docs}#{INDENT} */
FIELD_JAVADOC
        end
        gettersSetters << "#{INDENT}public #{wrapOpt(f.isRequired, typeDef)} #{DataMetaDom.getterName(f)}() {return this.#{f.name}; }\n"
      }
      out.puts(rxRoster.to_patterns)
      out.puts fieldDeclarations
      out.puts
      out.puts gettersSetters
      out.puts %|
#{INDENT}/**
#{INDENT}* If there is class type mismatch, somehow we are comparing apples to oranges, this is an error, not
#{INDENT}* a not-equal condition.
#{INDENT}*/
#{INDENT}@SuppressWarnings("EqualsWhichDoesntCheckParameterClass") @Override public boolean equals(Object other) {
#{INDENT * 2}return Objects.deepEquals(new Object[]{#{eqHashFields.map{|q| "this.#{q}"}.join(', ')}},
#{INDENT * 2}  new Object[]{#{eqHashFields.map{|q| "((#{baseName}) other).#{q}"}.join(', ')}});
#{INDENT}}
|
        out.puts %|
#{INDENT}@Override public int hashCode() {// null - safe: result = 31 * result + (element == null ? 0 : element.hashCode());
#{INDENT * 2}return Objects.hash(#{eqHashFields.map{|q| "this.#{q}"}.join(', ')});
#{INDENT}}
|
      verCalls = reqFields.map{|r| %<if(#{r} == null) missingFields.add("#{r}");>}.join("\n#{INDENT * 2}")
      out.puts %|
#{INDENT}public void verify() {
|
      unless verCalls.empty?
          out.puts %|
#{INDENT * 2}StringJoiner missingFields = new StringJoiner(", ");
#{INDENT * 2}#{verCalls}
#{INDENT * 2}if(missingFields.length() != 0) throw new VerificationException(getClass().getSimpleName() + ": required fields not set: " + missingFields);
|

      end

      out.puts %|

#{rxRoster.to_verifications}
#{fieldVerifications}
#{INDENT}}
|
      out.puts %<
#{INDENT}public final SemanticVersion getVersion() { return VERSION; }
}>
    end

# Unaggregated Java type
    def unaggrJavaType(dt, javaPackage)
        typeRenderer = JAVA_TYPES[dt.type]
        typeRenderer ? typeRenderer.call(dt) : DataMetaDom.condenseType(dt.type, javaPackage)
    end

# aggregated Java type
    def aggrJavaType(f, javaPackage)
        rawType = unaggrJavaType(f.dataType, javaPackage)
        aggr = f.aggr? ? DataMetaDom.splitNameSpace(AGGR_CLASSES[f.aggr])[1] : nil
        PojoLexer.aggrType(aggr, f.trgType, rawType, javaPackage)
    end

=begin
DataMetaSame condition generated for the given field. This applies only for a single instance.
All aggregation specifics are hhandled elsewhere (see genDataMetaSame)
=end
    def lsCondition(parser, f, javaPackage, suffix, imports, one, another)
        dt = f.dataType
        g = "#{DataMetaDom.getterName(f)}()"
        if false # Ruby prints the warning that the var is unused, unable to figure out that it is used in the ERB file
            # and adding insult to injury, the developers didn't think of squelching the false warnings
            p g
        end
        typeRec = parser.records[dt.type]
        enumType = parser.enums[dt.type]
        case
            when typeRec
                ftNs, ftClassBase = DataMetaDom.splitNameSpace(typeRec.name)
                # the name of the DataMetaSame implementor of the Field's type, assuming it is available during compile time
                ftLsClassBase = "#{ftClassBase}#{suffix}"
                # import the class if it belogns to a different package
                imports << "#{DataMetaDom.combineNsBase(ftNs, ftLsClassBase)}" unless javaPackage == ftNs
                %Q<#{ftLsClassBase}.I.isSame(#{one}, #{another})>

            when (f.isRequired && PRIMITIVABLE_TYPES.member?(dt.type)) || (enumType && enumType.kind_of?(DataMetaDom::Enum))
                %Q<(#{one} == #{another})>

            when enumType && enumType.kind_of?(DataMetaDom::Mappings)
                %Q<MAP_EQ.isSame(#{one}, #{another})>

            else # leverage the equals method, that works for the BitMaps too
                %Q<EQ.isSame(#{one}, #{another})>
        end
    end
=begin rdoc
Generates Java source code for the DataMetaSame implementor in Java to compare by all the fields in the class for the
given Record.

No attempt made to pretty-format the output. Pretty-formatting makes sense only when human eyes look at the
generated code in which case one keyboard shortcut gets the file pretty-formatted. Beside IDEs, there are
Java pretty-formatters that can be plugged in into the build process:

* {Jalopy}[http://jalopy.sourceforge.net]
* {JxBeauty}[http://members.aon.at/johann.langhofer/jxb.htm]
* {BeautyJ}[http://beautyj.berlios.de]

To name a few.

Parameters:
* +parser+ - the instance of Model
* +destDir+ - destination root.
* +javaPackage+ - Java package to export to
* +suffix+ - The suffix to append to the DataMeta DOM Class to get the DataMetaSame implementor's name.
* +dmClass+ - the name of DataMeta DOM class to generate for
* +record+ - the DataMeta DOM record to generate the DataMetaSame implementors for.
* +fields+ - a collection of fields to compare
=end
    def genDataMetaSame(parser, destDir, javaPackage, suffix, dmClass, record, fields)
        conditions = []
        aggrChecks = ''
        imports = javaImports(fields)
        javaClass = "#{dmClass}#{suffix}"
        fields.each { |f|
            g = "#{DataMetaDom.getterName(f)}()"
            if f.aggr?
                if f.set?
=begin
# no option with the Set for full compare -- a Set is a Set, must use equals and hashCode
but, if in future a need arises, could use the following pattern -- tested, the stream shortcut works fine:
        final Set<String> personas___1__ = one.getPersonas();
        final Set<String> personas___2__ = another.getPersonas();
        if(personas___1__ != personas___2__) {
            if(personas___1__ == null || personas___2__ == null ) return false; // one of them is null but not both -- not equal short-circuit
            if(personas___1__.size() != personas___2__.size()) return false;
            // this should run in supposedly O(N), since Set.contains(v) is supposedly O(1)
            final Optional<String> firstMismatch = personas___1__.stream().filter(v -> !personas___2__.contains(v)).findFirst();
            if(firstMismatch.isPresent()) return false;
        }
=end
                    conditions << %|(one.#{g} != null && one.#{g}.equals(another.#{g}))|
                else
                    a1 = "#{f.name}___1__"
                    a2 = "#{f.name}___2__"
                    li1 = "#{f.name}___li1__"
                    li2 = "#{f.name}___li2__"
                    jt = unaggrJavaType(f.dataType, javaPackage)
                    aggrChecks << %|
#{INDENT * 2}final #{aggrJavaType(f, javaPackage)} #{a1} = one.#{g};
#{INDENT * 2}final #{aggrJavaType(f, javaPackage)} #{a2} = another.#{g};
#{INDENT * 2}if(#{a1} != #{a2} )  {
#{INDENT * 3}if(#{a1} == null #{'||'} #{a2} == null ) return false; // one of them is null but not both -- not equal short-circuit
#{INDENT * 3}java.util.ListIterator<#{jt}> #{li1} = #{a1}.listIterator();
#{INDENT * 3}java.util.ListIterator<#{jt}> #{li2} = #{a2}.listIterator();
#{INDENT * 3}while(#{li1}.hasNext() && #{li2}.hasNext()) {
#{INDENT * 4}final #{jt} o1 = #{li1}.next(), o2 = #{li2}.next();
#{INDENT * 4}if(!(o1 == null ? o2 == null : #{lsCondition(parser, f, javaPackage, suffix, imports, 'o1', 'o2')})) return false; // shortcircuit to false
#{INDENT * 3}}
#{INDENT * 3}if(#{li1}.hasNext() #{'||'} #{li2}.hasNext()) return false; // leftover elements in one
#{INDENT * 2}}
|
                end
            elsif f.map?
                a1 = "#{f.name}___1__"
                a2 = "#{f.name}___2__"
                aggrChecks << %|
#{INDENT * 2}final java.util.Map<#{unaggrJavaType(f.dataType, javaPackage)}, #{unaggrJavaType(f.trgType, javaPackage)}> #{a1} = one.#{g};
#{INDENT * 2}final java.util.Map<#{unaggrJavaType(f.dataType, javaPackage)}, #{unaggrJavaType(f.trgType, javaPackage)}> #{a2} = another.#{g};
#{INDENT * 2}if(#{a1} != #{a2} )  {
#{INDENT * 3}if(#{a1} == null #{'||'} #{a2} == null ) return false; // one of them is null but not both -- not equal short-circuit
#{INDENT * 3}if(!#{a1}.equals(#{a2})) return false; // Maps are shallow-compared, otherwise logic and spread of semantics are too complex
#{INDENT * 2}}
|
            else # regular field
                conditions << lsCondition(parser, f, javaPackage, suffix, imports, "one.#{g}", "another.#{g}")
            end
        }
        out = File.open(File.join(destDir, "#{javaClass}.java"), 'wb')
        out.puts <<DM_SAME_CLASS
package #{javaPackage};

#{importSetToSrc(imports)}

import org.ebay.datameta.dom.DataMetaSame;
import org.ebay.datameta.util.jdk.SemanticVersion;

#{PojoLexer.classJavaDoc record.docs}public class #{javaClass} implements DataMetaSame<#{dmClass}>{
#{INDENT}/**
#{INDENT}* Convenience instance.
#{INDENT}*/
#{INDENT}public final static #{javaClass} I = new #{javaClass}();
#{INDENT}@Override public boolean isSame(final #{dmClass} one, final #{dmClass} another) {
#{INDENT * 2}if(one == another) return true; // same object or both are null
#{INDENT * 2}//noinspection SimplifiableIfStatement
#{INDENT * 2}if(one == null || another == null) return false; // whichever of them is null but the other is not
#{INDENT * 2}#{aggrChecks}
#{INDENT * 2}return #{conditions.join(' && ')};
#{INDENT}}
DM_SAME_CLASS
        if record.ver
            out.puts %Q<#{INDENT}public static final SemanticVersion VERSION = SemanticVersion.parse("#{record.ver.full}");>
        end
        out.puts '}'
        out.close
    end


=begin rdoc
Runs generation of Java source code for DataMetaSame implementors for the given parser into the given output path.

Parameters:
* +parser+ - an instance of DataMetaDom::Model
* +outRoot+ - the path to output the generated Java packages into
* +style+ - can pass one of the following values:
    * ID_ONLY_COMPARE - see the docs to it
    * FULL_COMPARE - see the docs to it
=end
    def genDataMetaSames(parser, outRoot, style = FULL_COMPARE)
        parser.records.values.each { |record|
            javaPackage, base, packagePath = assertNamespace(record.name)
            destDir = File.join(outRoot, packagePath)
            FileUtils.mkdir_p destDir
            case style
                when FULL_COMPARE
                    suffix = SAME_FULL_SFX
                    fields = record.fields.values
                when ID_ONLY_COMPARE
                    unless record.identity
                        L.warn "#{record.name} does not have identity defined"
                        next
                    end
                    suffix = SAME_ID_SFX
                    fields = record.fields.keys.select{|k| record.identity.hasArg?(k)}.map{|k| record.fields[k]}
                else; raise %Q<Unsupported DataMetaSame POJO style "#{style}">
            end
            if fields.empty?
                L.warn "#{record.name} does not have any fields to compare by"
                next
            end
            genDataMetaSame parser, destDir, javaPackage, suffix, base, record, fields
        }
    end

=begin rdoc
Generates Java source code for the worded enum, DataMeta DOM keyword "<tt>enum</tt>".
=end
    def genEnumWorded(out, enum, javaPackage, baseName)
      values = enum.keys.map{|k| enum[k]} # sort by ordinals to preserve the order
      out.puts <<ENUM_CLASS_HEADER
package #{javaPackage};
import javax.annotation.Nullable;
import java.util.HashMap;
import java.util.Map;

import org.ebay.datameta.dom.DataMetaEntity;
import org.ebay.datameta.util.jdk.SemanticVersion;
import static java.util.Collections.unmodifiableMap;

#{enumJavaDoc(enum.docs)}public enum #{baseName} implements DataMetaEntity {
  #{values.join(', ')};
  /**
   * Staple Java lazy init idiom.
   * See <a href="http://en.wikipedia.org/wiki/Initialization-on-demand_holder_idiom">this article</a>.
   */
  private static class LazyInit {
      final static Map<String, #{baseName}> NAME_TO_ENUM;
      final static #{baseName}[] ORD_TO_ENUM = new #{baseName}[values().length];

      static {
          final Map<String, #{baseName}> map = new HashMap<>(values().length * 3 / 2 + 1);
          for (int ix = 0; ix < values().length; ix++) {
              final #{baseName} val = values()[ix];
              ORD_TO_ENUM[ix] = val;
              map.put(val.name(), val);
          }
          NAME_TO_ENUM = unmodifiableMap(map);
      }
  }

  /**
   * Retrieve a value for the given textual form.
   * Lenient replacement for {@link Enum#valueOf(Class, java.lang.String)} that returns null
   * instead of throwing an exception.
   */
  @Nullable public static #{baseName} forName(final String textual) {
      return LazyInit.NAME_TO_ENUM.get(textual);
  }

  /**
   * Fast instance retrieval for the given ordinal, works super fast because it uses an array
   * indexing, not a map.
   */
  @Nullable public static #{baseName} forOrd(final int ordinal) {
      return LazyInit.ORD_TO_ENUM[ordinal];
  }

  public static interface Visitor<IN, OUT> {
ENUM_CLASS_HEADER

      values.each { |v|
        out.puts "        OUT visit#{v}(IN input);"
      }
      out.puts <<VISITOR_SWITCH_HEAD
    }

    /** Use this switch with your {@link Visitor} implementation,
     * There should be no other switches of this kind in your program.
     * If the enum changes, all implementations will break and will need to be fixed.
     * This will ensure that no unhandled cases will be left in the program.
     */
     public static <IN, OUT> OUT visit(final #{baseName} value, final Visitor<IN, OUT> visitor, final IN input) {
        switch(value) {
VISITOR_SWITCH_HEAD

      values.each { |v|
        out.puts "          case #{v}:\n              return visitor.visit#{v}(input);"
      }
      out.puts <<VISITOR_SWITCH_TAIL
            default:
                throw new IllegalArgumentException("Unsupported enum value: " + value);
        }
     }
VISITOR_SWITCH_TAIL
        if enum.ver
            out.puts %Q<    public static final SemanticVersion VERSION = SemanticVersion.parse("#{enum.ver.full}");>
        end

        out.puts %<
#{INDENT}public final SemanticVersion getVersion() { return VERSION; }
}>
    end

=begin rdoc
Generates Java source code for the DataMeta DOM Mapping, DataMeta DOM keyword "<tt>mapping</tt>".
=end
    def genMapping(out, mapping, javaPackage, baseName)
      keys = mapping.keys
      raise "Mapping too big, size = #{keys.length}, max size #{MAX_MAPPING_SIZE}" if keys.length > MAX_MAPPING_SIZE
      fromType = getJavaType(mapping.fromT)
      toType = getJavaType(mapping.toT)
      imports = {}
      importable = JAVA_IMPORTS[mapping.fromT.type]; imports[importable.to_sym] = 1 if importable
      importable = JAVA_IMPORTS[mapping.toT.type]; imports[importable.to_sym] = 1 if importable
      importText = imports.keys.to_a.map{|i| "import #{i};"}.join("\n")
      mapGeneric = "#{fromType}, #{toType}"
      out.puts <<MAPPING_CLASS_HEADER
package #{javaPackage};

import org.ebay.datameta.dom.Mapping;
#{importText}
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.ebay.datameta.util.jdk.SemanticVersion;

#{PojoLexer.classJavaDoc mapping.docs}public final class #{baseName} implements Mapping<#{mapGeneric}>{

    private final static Map<#{mapGeneric}> mapping;
    protected final static int count = #{keys.length};

    static {
        final Map<#{mapGeneric}> m = new HashMap<#{mapGeneric}>(count * 3 / 2 + 1);
MAPPING_CLASS_HEADER
      keys.sort.each { |k|
        out.puts %Q<#{INDENT*2}m.put(#{getJavaVal(mapping.fromT, k)}, #{getJavaVal(mapping.toT, mapping[k])});>
      }
      out.puts <<MAPPING_CLASS_FOOTER
        mapping = Collections.unmodifiableMap(m);
    }
    public static int size() { return mapping.size(); }
    public static boolean containsKey(#{fromType} key) { return mapping.containsKey(key); }
    public static #{toType} get(#{fromType} key) { return mapping.get(key); }
    public static Set<#{fromType}> keySet() { return mapping.keySet(); }
    public static Collection<#{toType}> values() { return mapping.values(); }
    private static void assertKey(#{fromType} key) {
        if(!mapping.containsKey(key)) throw new IllegalArgumentException("The key " + key
            + " does not belong to this mapping");
    }

    private #{fromType} key;

    public #{baseName}(){}
    public #{baseName}(#{fromType} key){ assertKey(key); this.key = key;}

    public void setKey(#{fromType} key) {assertKey(key); this.key = key; }
    public #{fromType} getKey() { return key; }
    public #{toType} getValue() { return mapping.get(key); }
    @Override public String toString() { return getClass().getSimpleName() + '{' + key + "=>" + mapping.get(key) + '}'; }
MAPPING_CLASS_FOOTER
        if mapping.ver
            out.puts %Q<    public static final SemanticVersion VERSION = SemanticVersion.parse("#{mapping.ver.full}");>
        end

        out.puts %<
#{INDENT}public final SemanticVersion getVersion() { return VERSION; }
}>

    end

=begin rdoc
Generates Java source code for the DataMeta DOM BitSet, DataMeta DOM keyword "<tt>bitset</tt>".
=end
    def genBitSet(out, bitSet, javaPackage, baseName)
      keys = bitSet.keys
      toType = getJavaType(bitSet.toT)
      importable = JAVA_IMPORTS[bitSet.toT.type]
      importTxt = importable ? "import #{importable};" : ''
      maxBit = bitSet.keys.max
      raise "Mapping too big, size = #{maxBit}, max size #{MAX_MAPPING_SIZE}" if maxBit > MAX_MAPPING_SIZE
      out.puts <<BIT_SET_HEADER
package #{javaPackage};

import org.ebay.datameta.dom.BitSetImpl;
import org.ebay.datameta.util.jdk.SemanticVersion;

#{importTxt}
#{PojoLexer.classJavaDoc bitSet.docs}public final class #{baseName} extends BitSetImpl<#{toType}>{
    public static final int MAX_BIT = #{maxBit};
    public static final int COUNT = MAX_BIT + 1;
  // we do not expect huge arrays here, the sizes should be very limited and likely continuous.
    private static final #{toType}[] mapping = new #{toType}[COUNT];
    static {
BIT_SET_HEADER

      keys.sort.each { |k|
        out.puts %Q<#{INDENT*2}mapping[#{k}] = #{getJavaVal(bitSet.toT, bitSet[k])};>
      }

      out.puts <<BIT_SET_FOOTER
    }

    public #{baseName}() {
    }

    public #{baseName}(long[] image) {
        super(image);
    }

    public final int getCount() { return COUNT; }
    public final #{toType}[] getMap() { return mapping;}
BIT_SET_FOOTER
        if bitSet.ver
            out.puts %Q<    public static final SemanticVersion VERSION = SemanticVersion.parse("#{bitSet.ver.full}");>
        end

        out.puts %<
#{INDENT}public final SemanticVersion getVersion() { return VERSION; }
}>

    end

=begin rdoc
Extracts 3 pieces of information from the given full name:
* The namespace if any, i.e. Java package, empty string if none
* The base name for the type, without the namespace
* Java package's relative path, the dots replaced by the file separator.

Returns an array of these pieces of info in this exact order as described here.
=end
    def assertNamespace(name)
      ns, base = DataMetaDom.splitNameSpace(name)
      javaPackage = DataMetaDom.validNs?(ns, base) ? ns : ''
      packagePath = javaPackage.empty? ? '' : javaPackage.gsub('.', File::SEPARATOR)

      [javaPackage, base, packagePath]
    end

=begin rdoc
Generates java sources for the model, the POJOs.
* Parameters
  * +parser+ - instance of Model
  * +outRoot+ - output directory
=end
    def genPojos(model, outRoot)
      (model.enums.values + model.records.values).each { |e|
        javaPackage, base, packagePath = assertNamespace(e.name)
        destDir = File.join(outRoot, packagePath)
        FileUtils.mkdir_p destDir
        out = File.open(File.join(destDir, "#{base}.java"), 'wb')
        begin
          case
            when e.kind_of?(DataMetaDom::Record)
              genEntity model, out, e, javaPackage, base
            when e.kind_of?(DataMetaDom::Mappings)
              genMapping out, e, javaPackage, base
            when e.kind_of?(DataMetaDom::Enum)
              genEnumWorded out, e, javaPackage, base
            when e.kind_of?(DataMetaDom::BitSet)
              genBitSet out, e, javaPackage, base
            else
              raise "Unsupported Entity: #{e.inspect}"
          end
        ensure
          out.close
        end
      }
    end

=begin
Generates migration guides from the given model to the given model
=end
    def genMigrations(mo1, mo2, outRoot)
        v1 = mo1.records.values.first.ver.full
        v2 = mo2.records.values.first.ver.full
        destDir = outRoot
        javaPackage = '' # set the scope for the var
        vars = OpenStruct.new # for template's local variables. ERB does not make them visible to the binding
        if false # Ruby prints the warning that the var is unused, unable to figure out that it is used in the ERB file
            # and adding insult to injury, the developers didn't think of squelching the false warnings
            p vars
            # it's interesting that there is no warning about the unused destDir and javaPackage. Duh!
        end
        # sort the models by versions out, 2nd to be the latest:
        raise ArgumentError, "Versions on the model are the same: #{v1}, nothing to migrate" if v1 == v2
        if v1 > v2
            model2 = mo1
            model1 = mo2
            ver1 = v2
            ver2 = v1
        else
            model2 = mo2
            model1 = mo1
            ver1 = v1
            ver2 = v2
        end

        puts "Migrating from ver #{ver1} to #{ver2}"
        ctxs = []
        droppedRecs = []
        addedRecs = []
        (model1.enums.values + model1.records.values).each { |srcE|
            trgRecName = flipVer(srcE.name, ver1.toVarName, ver2.toVarName)
            trgE = model2.records[trgRecName] || model2.enums[trgRecName]
            droppedRecs << srcE.name unless trgE
        }

        (model2.enums.values + model2.records.values).each { |trgE|
            srcRecName = flipVer(trgE.name, ver2.toVarName, ver1.toVarName)
            srcE = model1.records[srcRecName] || model1.enums[srcRecName]
            unless srcE
                addedRecs << trgE.name
                next
            end
            javaPackage, baseName, packagePath = assertNamespace(trgE.name)
            javaClassName = migrClass(baseName, ver1, ver2)
            destDir = File.join(outRoot, packagePath)
            migrCtx = MigrCtx.new trgE.name
            ctxs << migrCtx
            FileUtils.mkdir_p destDir
            javaDestFile = File.join(destDir, "#{javaClassName}.java")
            case
                when trgE.kind_of?(DataMetaDom::Record)
                    if File.file?(javaDestFile)
                        migrCtx.isSkipped = true
                        $stderr.puts %<Migration target "#{javaDestFile} present, therefore skipped">
                    else
                        IO::write(javaDestFile,
                                  ERB.new(IO.read(File.join(File.dirname(__FILE__), '../../tmpl/java/migrationEntityEnums.erb')),
                                          $SAFE, '%<>').result(binding), mode: 'wb')
                    end
                when trgE.kind_of?(DataMetaDom::Mappings)
                    $stderr.puts "WARN: Migration guides for the mapping #{trgE.name} are not generated; migration is not implemented for mappings"
                when trgE.kind_of?(DataMetaDom::Enum)
                    # handled by the POJO migrator above, i.e. the case when trgE.kind_of?(DataMetaDom::Record)
                when trgE.kind_of?(DataMetaDom::BitSet)
                    $stderr.puts "WARN: Migration guides for the bitset #{trgE.name} are not generated; migration is not implemented for bitsets"
                else
                    raise "Unsupported Entity: #{trgE.inspect}"
            end
        }
        noAutos = ctxs.reject{|c| c.canAuto}
        skipped = ctxs.select{|c| c.isSkipped}

        $stderr.puts %<Migration targets skipped: #{skipped.size}> unless skipped.empty?

        unless noAutos.empty?
            $stderr.puts %<#{noAutos.size} class#{noAutos.size > 1 ? 'es' : ''} out of #{ctxs.size} can not be migrated automatically:
#{noAutos.map{|c| c.rec}.sort.join("\n")}
Please edit the Migrate_ code for #{noAutos.size > 1 ? 'these' : 'this one'} manually.
>
        end

        unless droppedRecs.empty?
            $stderr.puts %<#{droppedRecs.size} class#{droppedRecs.size > 1 ? 'es were' : ' was'} dropped from your model:
#{droppedRecs.sort.join("\n")}
-- you may want to review if #{droppedRecs.size > 1 ? 'these were' : 'this one was'} properly handled.
>
        end

        unless addedRecs.empty?
            $stderr.puts %<#{addedRecs.size} class#{addedRecs.size > 1 ? 'es were' : ' was'} added to your model:
#{addedRecs.sort.join("\n")}
-- no migration guides were generated for #{addedRecs.size > 1 ? 'these' : 'this one'}.
>
        end

    end

=begin rdoc
Runs DataMetaSame generator for the given style.

Parameters:
* +style+ - FULL_COMPARE or ID_ONLY_COMPARE
* +runnable+ - the name of the executable script that called this method, used for help
=end
    def dataMetaSameRun(style, runnable, source, target, options={autoVerNs: true})
        @source, @target = source, target
        helpDataMetaSame runnable, style unless @source && @target
        helpDataMetaSame(runnable, style, "DataMeta DOM source #{@source} is not a file") unless File.file?(@source)
        helpDataMetaSame(runnable, style, "DataMetaSame destination directory #{@target} is not a dir") unless File.directory?(@target)

        @parser = Model.new
        begin
          @parser.parse(@source, options)
          genDataMetaSames(@parser, @target, style)
        rescue Exception => e
           puts "ERROR #{e.message}; #{@parser.diagn}"
           puts e.backtrace.inspect
        end
    end

    # Shortcut to help for the Full Compare DataMetaSame generator.
    def helpDataMetaSame(file, style, errorText=nil)
        styleWording = case style
                           when FULL_COMPARE; "Full"
                           when ID_ONLY_COMPARE; "Identity Only"
                           else raise %Q<Unsupported identity style "#{style}">
                       end
        help(file, "#{styleWording} Compare DataMetaSame generator", '<DataMeta DOM source> <target directory>', errorText)
    end

# Switches Namespace version part on a versioned DataMeta DOM entity.
    def flipVer(fullName, from, to)
        fullName.to_s.gsub(".v#{from}.", ".v#{to}.").to_sym
    end

# The field must be an aggregate. The method puts together an argument for the proper collection setter
    def setAggrPrims(trgFld)
       #new LinkedList<>(src.getInts().stream().map(Integer::longValue).collect(Collectors.toList()))
        case trgFld.aggr
            when Field::SET
                %|src.#{DataMetaDom.getterName(trgFld)}().stream().map(e -> e.#{primValMethod(trgFld.dataType)}()).collect(toSet())|
            when Field::LIST
                %|new ArrayList<>(src.#{DataMetaDom.getterName(trgFld)}().stream().map(e -> e.#{primValMethod(trgFld.dataType)}()).collect(toList()))|
            when Field::DEQUE
                %|new LinkedList<>(src.#{DataMetaDom.getterName(trgFld)}().stream().map(e -> e.#{primValMethod(trgFld.dataType)}()).collect(toList()))|
            else
                raise ArgumentError, %<Unsupported aggregation type on the field:
#{trgFld}>
        end
    end
    module_function :getJavaType, :getJavaVal, :wrapOpt, :classJavaDoc,
                :assertNamespace, :dataMetaSameRun, :genDataMetaSames, :genDataMetaSame, :helpDataMetaSame, :javaImports,
                :javaDocs, :genPojos, :genEntity, :flipVer, :primValMethod, :importSetToSrc, :aggrJavaType,
                :unaggrJavaType, :lsCondition
end

end
