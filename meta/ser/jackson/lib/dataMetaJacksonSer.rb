$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# Definition for generating Plain Old Java Objects (POJOs)
%w(fileutils dataMetaDom dataMetaDom/pojo dataMetaDom/enum dataMetaDom/record dataMetaDom/help dataMetaDom/util
    ).each(&method(:require))

require 'set'
require 'dataMetaJacksonSer/util'

=begin rdoc
JSON Serialization artifacts generation.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
module DataMetaJacksonSer
    # Current version
    VERSION = '2.0.1'
    include DataMetaDom, DataMetaDom::PojoLexer

=begin rdoc
HDFS Reader and Writer for textual Java types such as String.
=end
    TEXT_RW_METHODS = RwHolder.new(
            lambda{|ctx|
                ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}String(in)") : ctx.rw.call('JU.readText(in)')
            },
            lambda{|ctx|
                 ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}String(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})" : "out.writeStringField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"
            }
    )

=begin rdoc
HDFS Reader and Writer for integral Java types such as Integer or Long.
=end
    INTEGRAL_RW_METHODS = RwHolder.new(
                lambda{ |ctx|
                    mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                    case
                        when ctx.fType.length <= 4; ctx.fld.aggr ? ctx.rw.call("JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Integer(in)") :
                                ctx.rw.call("in.getIntValue#{ctx.|}")

                        when ctx.fType.length <= 8; ; ctx.fld.aggr ? ctx.rw.call("JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Long(in)") : ctx.rw.call("in.getLongValue#{ctx.|}")

                        else; raise "Invalid integer field #{ctx.fld}"
                    end
                  },
                lambda{ |ctx|
                  case
                      when ctx.fType.length <= 4; ctx.fld.aggr ? "JU.write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))
                        }Integer(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})" :
                        "out.writeNumberField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"

                      when ctx.fType.length <= 8;  ctx.fld.aggr ? "JU.write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))
                        }Long(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})" :
                        "out.writeNumberField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"

                      else; raise "Invalid integer field #{ctx.fld}"
                  end
                })

=begin rdoc
HDFS Reader and Writer for floating point Java types such as Float or Double.
=end
    FLOAT_RW_METHODS = RwHolder.new(
                lambda{|ctx|
                    mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                    case
                      when ctx.fType.length <= 4; ctx.fld.aggr ? ctx.rw.call("JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Float(in)") : ctx.rw.call('in.getFloatValue()')
                      when ctx.fType.length <= 8; ctx.fld.aggr ? ctx.rw.call("JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Double(in)") : ctx.rw.call('in.getDoubleValue()')
                      else; raise "Invalid float field #{ctx.fld}"
                    end
                  },
                lambda{|ctx|
                    case
                      when ctx.fType.length <= 4; ctx.fld.aggr ? "JU.write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Float(out, value.#{ctx.valGetter}#{ctx.|})" : "out.writeNumberField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"
                      when ctx.fType.length <= 8; ctx.fld.aggr ? "JU.write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Double(out, value.#{ctx.valGetter}#{ctx.|})" : "out.writeNumberField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"
                      else; raise "Invalid float field #{ctx.fld}"
                    end
              })

=begin rdoc
HDFS Reader and Writer for the temporal type, the DateTime
=end
    DTTM_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                ctx.fld.aggr ? ctx.rw.call("JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}ZonedDateTime(in)") : ctx.rw.call('JU.readDttm(in)')
            },
            lambda { |ctx|
                 ctx.fld.aggr ? %<JU.write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}ZonedDateTime("#{
                    ctx.fld.name}", out, value.#{ctx.valGetter}#{ctx.|})> : "JU.writeDttmFld(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})"
            }
    )

=begin rdoc
HDFS Reader and Writer for boolean Java type.
=end
    BOOL_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Booleans') if ctx.fld.aggr
                ctx.rw.call('in.getBooleanValue()')
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Booleans') if ctx.fld.aggr
                "out.writeBooleanField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"
            }
    )

=begin rdoc
HDFS Reader and Writer the raw data type, the byte array.
=end
    RAW_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Raw Data') if ctx.fld.aggr
                ctx.rw.call('JU.readByteArrayPrim(in)')
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Raw Data') if ctx.fld.aggr
                "JU.writeByteArrayFld(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})" }
    )

=begin rdoc
HDFS Reader and Writer the variable size Decimal data type.
=end
    NUMERIC_RW_METHODS = RwHolder.new(lambda{|ctx| ctx.fld.aggr ? ctx.rw.call("JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}BigDecimal(in)") : ctx.rw.call('JU.readBigDecimal(in)')},
                                      lambda{|ctx| "out.writeNumberField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|})"})

=begin rdoc
HDFS Reader and Writer the Java Enums.
=end
    ENUM_RW_METHODS = RwHolder.new(
          lambda{|ctx|
            aggrNotSupported(ctx.fld, 'Enums') if ctx.fld.aggr
            "Enum.valueOf(#{DataMetaDom.condenseType(ctx.fType.type, ctx.pckg)}.class, JU.readText(in))"
          },
          lambda { |ctx|
            aggrNotSupported(ctx.fld, 'Enums') if ctx.fld.aggr
            "out.writeStringField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|}.name())"
          }
    )

=begin rdoc
HDFS Reader and Writer the BitSet.
=end
    BITSET_RW_METHODS = RwHolder.new(
          lambda { |ctx|
            aggrNotSupported(ctx.fld, 'BitSets') if ctx.fld.aggr
            "new #{DataMetaDom.condenseType(ctx.fld.dataType, ctx.pckg)}(readLongArray(in))"
          },
          lambda { |ctx|
            aggrNotSupported(ctx.fld, 'BitSets') if ctx.fld.aggr
            "writeBitSetFld(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})"
          }
    )

=begin rdoc
HDFS Reader and Writer the URL.
=end
    URL_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'URLs') if ctx.fld.aggr
                'new java.net.URL(in.getText())'
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'URLs') if ctx.fld.aggr
                "out.writeStringField(\"#{ctx.fld.name}\", value.#{ctx.valGetter}#{ctx.|}.toExternalForm())"
            }
    )
=begin rdoc
Read/write methods for the standard data types.
=end
    STD_RW_METHODS = {
          INT => INTEGRAL_RW_METHODS,
          STRING => TEXT_RW_METHODS,
          DATETIME => DTTM_RW_METHODS,
          BOOL => BOOL_RW_METHODS,
          CHAR => TEXT_RW_METHODS,
          FLOAT => FLOAT_RW_METHODS,
          RAW => RAW_RW_METHODS,
          NUMERIC => NUMERIC_RW_METHODS,
          URL => URL_RW_METHODS
    }
# DataMeta DOM object renderer
    RECORD_RW_METHODS = RwHolder.new(
        lambda { |ctx|
            if ctx.fld.aggr
                if ctx.fld.trgType # map
                    mapsNotSupported(ctx.fld)
                else  # list, set or deque
                    "JU.read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}(in, #{
                        jsonableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance())"
                end
            else # scalar
                "#{jsonableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance().read(in)"
            end
        },
        lambda { |ctx|
            if ctx.fld.aggr && !ctx.fld.trgType
                if ctx.fld.trgType # map
                    mapsNotSupported(ctx.fld)
                else  # list, set or deque
                    "JU.writeCollectionFld(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|}, #{jsonableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance())"
                end
            else # scalar
                "#{jsonableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance().writeField(\"#{ctx.fld.name}\", out, value.#{ctx.valGetter}#{ctx.|})"
            end
        }
    )

# Transforms the given DataMeta DOM aggregate type to full pathed Java class name
    def aggrJavaFull(aggr)
        PojoLexer::AGGR_CLASSES[aggr] || (raise ArgumentError, "No Aggregate classes for type #{aggr}" )
    end

# Transforms the given full Java name for the aggregate class into base name to interpolate into methods
    def aggrBaseName(aggr)
        /^(\w+\.)+(\w+)$/.match(aggr)[2]
    end
=begin rdoc
Read/write methods for the DataMeta DOM Maps, accidentally all the same as for the standard data types.
=end
    MAP_RW_METHODS = STD_RW_METHODS

    # Build the Read/Write operation renderer for the given context:
    def getRwRenderer(ctx)
        dt = ctx.fld.dataType
        ctx.refType = nil # reset to avoid misrendering primitives
        rwRenderer = STD_RW_METHODS[dt.type]
        return rwRenderer if rwRenderer
        refKey = dt.type
        ctx.refType = ctx.model.enums[refKey] || ctx.model.records[refKey]
        case
            when ctx.refType.kind_of?(DataMetaDom::Record)
                RECORD_RW_METHODS
            when ctx.refType.kind_of?(DataMetaDom::Enum)
                ENUM_RW_METHODS
            when ctx.refType.kind_of?(DataMetaDom::BitSet)
                BITSET_RW_METHODS
            when ctx.refType.kind_of?(DataMetaDom::Mapping)
                MAP_RW_METHODS[ctx.fType.type] || (raise ArgumentError, "No renderer found for the key type #{
                ctx.fType.type}, record #{ctx.rec}, field #{ctx.fld}")
            else
                raise "No renderer defined for field #{ctx.fld}"
        end
    end

# Temporary/scratch var -- avoiding collisions at all costs
    def tmpVar(name); "#{'_'*3}#{name}#{'_'*3}" end

  # generates Scala JSONable via delegation
  def genJacksonable(model, ioOut, record, javaPackage, baseName, fmt = :scala)
    assertOutFmt fmt
    ctx = RendCtx.new.init(model, record, javaPackage, baseName)
    fields = record.fields
    ioName = jsonableClassName(baseName)
    # scan for imports needed
    hasOptional = fields.values.map{|f|
#      !model.records[f.dataType.type] &&
              !f.isRequired
    }.reduce(:|) # true if there is at least one optional field which isn't a record
    #fields.values.each { |f|
    #      ctx << DataMetaDom::PojoLexer::JAVA_IMPORTS[f.dataType.type]
    #}

    # field keys (names) in the order of reading/writing to the in/out record
    keysInOrder = fields.each_key.map{|k| k.to_s}.sort.map{|k| k.to_sym}
    reads = ''
    writes = ''
    indent = "#{' ' * 2}"
    # sorting provides predictable read/write order
    keysInOrder.each { |k|
      f = fields[k]
      ctx.fld = f
      rwRenderer = getRwRenderer(ctx)
#      unless ctx.refType.kind_of?(DataMetaDom::Record)

      reads << case fmt
        when SCALA_FMT
          %/
          #{indent*5}case "#{f.name}" =>
#{indent*6}target.#{DataMetaDom.setterName(ctx.fld)}(#{rwRenderer.r.call(ctx)})
/
        when JAVA_FMT
          %/
#{indent*6}case "#{f.name}":
#{indent*7}target.#{DataMetaDom.setterName(ctx.fld)}(#{rwRenderer.r.call(ctx)});
#{indent*7}break;
/
        else
          badFmt fmt
      end

# rendering of noReqFld - using the Verifiable interface instead
#=begin
      writes  << case fmt
        when SCALA_FMT
           "\n" + (indent*2) + (f.isRequired ?
                (PRIMITIVABLE_TYPES.member?(f.dataType.type) ? '' : ''):
#%Q<if(value.#{DataMetaDom::PojoLexer::getterName(ctx.fld)}() == null) throw noReqFld("#{f.name}"); >) :
                "if(value.#{DataMetaDom.getterName(ctx.fld)} != null) ") + "#{rwRenderer.w.call(ctx)}"
#=end
        when JAVA_FMT
          "\n" + (indent*2) + (f.isRequired ?
              (PRIMITIVABLE_TYPES.member?(f.dataType.type) ? '' : ''):
              "if(value.#{DataMetaDom.getterName(ctx.fld)}#{ctx.|} != null) ") + "#{rwRenderer.w.call(ctx)};"
        else
          badFmt fmt
      end
    }

    ioOut.puts case fmt
      when SCALA_FMT
          %^
package #{javaPackage}

import org.ebay.datameta.ser.jackson.fasterxml.JacksonUtil._
import org.ebay.datameta.ser.jackson.fasterxml.Jsonable
import com.fasterxml.jackson.core.{JsonFactory, JsonGenerator, JsonParser, JsonToken}
import com.fasterxml.jackson.core.JsonToken.{END_ARRAY, END_OBJECT}

#{DataMetaDom::PojoLexer.classJavaDoc({})}object #{ioName} extends Jsonable[#{baseName}] {

  override def write(out: JsonGenerator, value: #{baseName}) {
    value.verify()
#{writes}
  }

  override def readInto(in: JsonParser, target: #{baseName}, ignoreUnknown: Boolean = true): #{baseName} = {
    while(in.nextToken() != END_OBJECT) {
      val fldName = in.getCurrentName
      if(fldName != null) {
        in.nextToken()
        fldName match {
#{reads}
          case _ => if(!ignoreUnknown) throw new IllegalArgumentException(s"""Unhandled field "$fldName" """)
        }
      }
    }
    target
  }

  override def read(in: JsonParser, ignoreUnknown: Boolean = true): #{baseName} = {
    readInto(in, new #{baseName}(), ignoreUnknown)
  }
}
^
      when JAVA_FMT
                          %^
package #{javaPackage};

import static org.ebay.datameta.ser.jackson.fasterxml.JacksonUtil.*;
import org.ebay.datameta.ser.jackson.fasterxml.JacksonUtil;
import org.ebay.datameta.ser.jackson.fasterxml.Jsonable;
import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.JsonToken;

import java.io.IOException;

import static com.fasterxml.jackson.core.JsonToken.END_ARRAY;
import static com.fasterxml.jackson.core.JsonToken.END_OBJECT;

/**
 * Json Serializer/Deserializer for the type {@link #{baseName}}.
 * This class is completely immutable, state-free and therefore thread-safe, implemented and used as a singleton.
 */
#{DataMetaDom::PojoLexer.classJavaDoc({})}public class #{ioName} extends Jsonable<#{baseName}> {

  /** An instance of the {@link JacksonUtil} - can use it anywhere because {@link JacksonUtil} is a singleton,
   * immutable and state-free.
   */
  public final static JacksonUtil JU = JacksonUtil.getInstance();

  public static #{ioName} getInstance() { return INSTANCE; }

  private final static #{ioName} INSTANCE = new #{ioName}();

  /**
   * Constructor is private - use {@link #getInstance()} to get an instance.
   */
  private #{ioName}() {}

  public void write(final JsonGenerator out, final #{baseName} value) throws IOException {
    value.verify();
#{writes}
  }

  public #{baseName} readInto(final JsonParser in, final #{baseName} target, final boolean ignoreUnknown) throws IOException {
    JsonToken t = null;
    while ( (t = in.nextToken()) != END_OBJECT) {
      if(t == null) throw new IllegalArgumentException("NULL token at " + in.getParsingContext());
      final String fldName = in.getCurrentName();
      if(fldName != null) {
        in.nextToken();
        switch(fldName){
            case "#{VER_KEY}": break; // skip the version field
            case "#{DT_KEY}": break;  // skip the data type field
#{reads}
          default:
            if(!ignoreUnknown) throw new IllegalArgumentException("Unhandled field \\"" + fldName + '\\"');
        }
      }
    }
    return target;
  }

  public #{baseName} read(final JsonParser in, boolean ignoreUnknown) throws IOException {
    return readInto(in, new #{baseName}(), ignoreUnknown);
  }
}
^
                      else
                          badFmt fmt

end

  end

=begin rdoc
Generates all the writables for the given model.
Parameters:
* +model+ - the model to generate Writables from.
* +outRoot+ - destination directory name.
=end
    def genJacksonables(model, outRoot, fmt = :scala)
      assertOutFmt fmt
      model.records.values.each { |e|
        javaPackage, base, packagePath = DataMetaDom::PojoLexer::assertNamespace(e.name)
        destDir = File.join(outRoot, packagePath)
        FileUtils.mkdir_p destDir
        ioOut = File.open(File.join(destDir, "#{jsonableClassName(base)}.#{fmt}"), 'wb')
        begin
          case
            when e.kind_of?(DataMetaDom::Record)
              genJacksonable model, ioOut, e, javaPackage, base, fmt
            else
              raise "Unsupported Entity: #{e.inspect}"
          end
        ensure
            ioOut.close
        end
      }
    end

    # Shortcut to help for the Hadoop Writables generator.
    def helpDataMetaJacksonSerGen(file, errorText=nil)
        DataMetaDom::help(file, 'DataMeta Serialization to/from Jackson', '<DataMeta DOM source> <Target Directory> [java | scala]', errorText)
    end

module_function :helpDataMetaJacksonSerGen, :genJacksonables, :genJacksonable, :getRwRenderer,
            :aggrBaseName, :aggrJavaFull
end
