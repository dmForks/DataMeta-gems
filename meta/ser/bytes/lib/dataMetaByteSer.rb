$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# Definition for generating Plain Old Java Objects (POJOs)
%w(fileutils dataMetaDom dataMetaDom/pojo dataMetaDom/enum dataMetaDom/record dataMetaDom/help dataMetaDom/util).each(&method(:require))
require 'set'
require 'dataMetaByteSer/util'

=begin rdoc
Serialization artifacts generation such as Hadoop Writables etc.

TODO this isn't a bad way, but beter use templating next time such as {ERB}[http://ruby-doc.org/stdlib-1.9.3/libdoc/erb/rdoc/ERB.html].

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
module DataMetaByteSer
    # Current version
    VERSION = '1.0.6'
    include DataMetaDom, DataMetaDom::PojoLexer

=begin rdoc
HDFS Reader and Writer for textual Java types such as String.
=end
    TEXT_RW_METHODS = RwHolder.new(
            lambda{|ctx|
                ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}String(in)") : ctx.rw.call('readText(in)')
            },
            lambda{|ctx|
                 ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}String(out, val.#{ctx.valGetter})" : "writeTextIfAny(out, val.#{ctx.valGetter})"
            }
    )

=begin rdoc
HDFS Reader and Writer for integral Java types such as Integer or Long.
=end
    INTEGRAL_RW_METHODS = RwHolder.new(
                lambda{ |ctx|
                    mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                    case
                        when ctx.fType.length <= 4; ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Integer(in)") :
                                ctx.rw.call('readVInt(in)')

                        when ctx.fType.length <= 8; ; ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Long(in)") : ctx.rw.call('readVLong(in)')

                        else; raise "Invalid integer field #{ctx.fld}"
                    end
                  },
                lambda{ |ctx|
                  case
                      when ctx.fType.length <= 4; ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Integer(out, val.#{ctx.valGetter})" :
                              "writeVInt(out, val.#{ctx.valGetter})"

                      when ctx.fType.length <= 8;  ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Long(out, val.#{ctx.valGetter})" : "writeVLong(out, val.#{ctx.valGetter})"

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
                      when ctx.fType.length <= 4; ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Float(in)") : ctx.rw.call('in.readFloat()')
                      when ctx.fType.length <= 8; ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Double(in)") : ctx.rw.call('in.readDouble()')
                      else; raise "Invalid float field #{ctx.fld}"
                    end
                  },
                lambda{|ctx|
                    case
                      when ctx.fType.length <= 4; ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Float(out, val.#{ctx.valGetter})" : "out.writeFloat(val.#{ctx.valGetter})"
                      when ctx.fType.length <= 8; ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Double(out, val.#{ctx.valGetter})" : "out.writeDouble(val.#{ctx.valGetter})"
                      else; raise "Invalid float field #{ctx.fld}"
                    end
              })

=begin rdoc
HDFS Reader and Writer for the temporal type, the DateTime
=end
    DTTM_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}ZonedDateTime(in)") : ctx.rw.call('readDttm(in)')
            },
            lambda { |ctx|
                 ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}ZonedDateTime(out, val.#{ctx.valGetter})" : "writeDttm(out, val.#{ctx.valGetter})"
            }
    )

=begin rdoc
HDFS Reader and Writer for boolean Java type.
=end
    BOOL_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Booleans') if ctx.fld.aggr
                ctx.rw.call('in.readBoolean()')
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Booleans') if ctx.fld.aggr
                "out.writeBoolean(val.#{ctx.valGetter})"
            }
    )

=begin rdoc
HDFS Reader and Writer the raw data type, the byte array.
=end
    RAW_RW_METHODS = RwHolder.new(
            lambda { |ctx|
              ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Enum(in, #{ctx.fld.dataType.type}.class)") : ctx.rw.call('readByteArray(in)')
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Raw Data') if ctx.fld.aggr
                ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}ZonedDateTime(out, val.#{ctx.valGetter})" : "writeByteArray(out, val.#{ctx.valGetter})" }
    )

=begin rdoc
HDFS Reader and Writer the variable size Decimal data type.
=end
    NUMERIC_RW_METHODS = RwHolder.new(lambda{|ctx| ctx.fld.aggr ? ctx.rw.call("read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}BigDecimal(in)") : ctx.rw.call('readBigDecimal(in)')},
                                      lambda{|ctx| "writeBigDecimal(out, val.#{ctx.valGetter})"})

=begin rdoc
HDFS Reader and Writer the Java Enums.
=end
    ENUM_RW_METHODS = RwHolder.new(
          lambda{|ctx|
            ctx.fld.aggr ? "read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Enum(in, #{ctx.fType.type}.class)" : "#{DataMetaDom.condenseType(ctx.fType.type, ctx.pckg)}.forOrd(readVInt(in))"
          },
          lambda { |ctx|
            ctx.fld.aggr ? "write#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}Enum(out, val.#{ctx.valGetter})" : "writeVInt(out, val.#{ctx.valGetter}.ordinal())"
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
            "writeBitSet(out, val.#{ctx.valGetter})"
          }
    )

=begin rdoc
HDFS Reader and Writer the URL.
=end
    URL_RW_METHODS = RwHolder.new(
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'URLs') if ctx.fld.aggr
                'new java.net.URL(readText(in))'
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'URLs') if ctx.fld.aggr
                "writeTextIfAny(out, val.#{ctx.valGetter}.toExternalForm())"
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
                    "read#{aggrBaseName(aggrJavaFull(ctx.fld.aggr))}(in, #{
                        inOutableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance())"
                end
            else # scalar
                "#{inOutableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance().read(in)"
            end
        },
        lambda { |ctx|
            if ctx.fld.aggr && !ctx.fld.trgType
                if ctx.fld.trgType # map
                    mapsNotSupported(ctx.fld)
                else  # list, set or deque
                    "writeCollection(val.#{ctx.valGetter}, out, #{inOutableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance())"
                end
            else # scalar
                "#{inOutableClassName(DataMetaDom.condenseType(ctx.fType.type, ctx.pckg))}.getInstance().write(out, val.#{ctx.valGetter})"
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

  # generates writable via delegation
  def genWritable(model, wriOut, ioOut, record, javaPackage, baseName)
    ctx = RendCtx.new.init(model, record, javaPackage, baseName)
    fields = record.fields
    wriName = writableClassName(baseName)
    ioName = inOutableClassName(baseName)
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
    writeNullMaskHead = hasOptional ? 'final BitSet nullFlags = new BitSet(); int fldIndex = -1;' : ''
    readNullMaskHead = hasOptional ? 'final BitSet nullFlags = new BitSet(readLongArray(in), false); int fldIndex = -1;' : ''
    indent = "\n#{' ' * 8}"
    # sorting provides predictable read/write order
    keysInOrder.each { |k|
      f = fields[k]
      ctx.fld = f
      rwRenderer = getRwRenderer(ctx)
#      unless ctx.refType.kind_of?(DataMetaDom::Record)
        reads <<  (
            indent + (f.isRequired ? '' : 'fldIndex++;') + "val.#{DataMetaDom.setterName(ctx.fld)}(" +
                (f.isRequired ? '' : 'nullFlags.get(fldIndex) ? null : ')+
            "#{rwRenderer.r.call(ctx)});"
        )
# rendering of noReqFld - using the Veryfiable interface instead
#=begin
        writes << (indent + (f.isRequired ?
                (PRIMITIVABLE_TYPES.member?(f.dataType.type) ? '' : ''):
#%Q<if(val.#{DataMetaDom::PojoLexer::getterName(ctx.fld)}() == null) throw noReqFld("#{f.name}"); >) :
                "if(val.#{DataMetaDom.getterName(ctx.fld)}() != null) ") + "#{rwRenderer.w.call(ctx)};")
        unless f.isRequired
          writeNullMaskHead << (indent + "fldIndex++; if(val.#{DataMetaDom.getterName(ctx.fld)}() == null) nullFlags.set(fldIndex);")
        end
#=end
#      end
    }
    writeNullMaskHead << ( indent + 'writeBitSet(out, nullFlags);') if hasOptional
    ioOut.puts <<IN_OUTABLE_CLASS
package #{javaPackage};
import org.ebay.datameta.dom.*;
import java.io.*;
import static org.ebay.datameta.ser.bytes.DataMetaHadoopUtil.*;
import static org.apache.hadoop.io.WritableUtils.*;
import org.ebay.datameta.ser.bytes.InOutable;
#{ctx.importsText}
#{DataMetaDom::PojoLexer.classJavaDoc({})}public class #{ioName} extends InOutable<#{baseName}> {

    private static final #{ioName} INSTANCE = new #{ioName}();
    public static #{ioName} getInstance() { return INSTANCE; }
    private #{ioName}() {}

    @Override public void write(final DataOutput out, final #{baseName} val) throws IOException {
        val.verify();
        #{writeNullMaskHead}
#{writes}
    }

    @Override public #{baseName} read(final DataInput in, final #{baseName} val) throws IOException {
        #{readNullMaskHead}
#{reads}
        return val;
    }
    @Override public #{baseName} read(final DataInput in) throws IOException {
        return read(in, new #{baseName}());
    }
}
IN_OUTABLE_CLASS
      wriOut.puts <<WRITABLE_CLASS
package #{javaPackage};
import org.apache.hadoop.io.Writable;
import org.ebay.datameta.dom.*;
import java.io.*;
import static org.ebay.datameta.ser.bytes.DataMetaHadoopUtil.*;
import static org.apache.hadoop.io.WritableUtils.*;
import org.ebay.datameta.ser.bytes.HdfsReadWrite;
#{ctx.importsText}
#{DataMetaDom::PojoLexer.classJavaDoc({})}public class #{wriName} extends HdfsReadWrite<#{baseName}> {

    public #{wriName}(final #{baseName} value) {
        super(value);
    }

    public #{wriName}() {
        super(new #{baseName}()); // the value must be on the instance at all times,
// for example, when used with hadoop fs -text, this class will be used with default constructor
    }

    @Override public void write(final DataOutput out) throws IOException {
        #{ioName}.getInstance().write(out, getVal());
    }

    @Override public void readFields(final DataInput in) throws IOException {
        #{ioName}.getInstance().read(in, getVal());
    }
}
WRITABLE_CLASS

      ########assertValue();
  end

=begin rdoc
Generates all the writables for the given model.
Parameters:
* +model+ - the model to generate Writables from.
* +outRoot+ - destination directory name.
=end
    def genWritables(model, outRoot)
      model.records.values.each { |e|
        javaPackage, base, packagePath = DataMetaDom::PojoLexer::assertNamespace(e.name)
        destDir = File.join(outRoot, packagePath)
        FileUtils.mkdir_p destDir
        wriOut = File.open(File.join(destDir, "#{writableClassName(base)}.java"), 'wb')
        ioOut = File.open(File.join(destDir, "#{inOutableClassName(base)}.java"), 'wb')
        begin
          case
            when e.kind_of?(DataMetaDom::Record)
              genWritable model, wriOut, ioOut, e, javaPackage, base
            else
              raise "Unsupported Entity: #{e.inspect}"
          end
        ensure
            begin
               ioOut.close
            ensure
               wriOut.close
            end
        end
      }
    end

    # Shortcut to help for the Hadoop Writables generator.
    def helpDataMetaBytesSerGen(file, errorText=nil)
        DataMetaDom::help(file, 'DataMeta Serialization to/from Bytes', '<DataMeta DOM source> <Target Directory>', errorText)
    end

module_function :helpDataMetaBytesSerGen, :genWritables, :genWritable, :getRwRenderer,
            :aggrBaseName, :aggrJavaFull
end
