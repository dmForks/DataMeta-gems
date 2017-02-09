$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'fileutils'
require 'dataMetaDom'
require 'dataMetaDom/util'
require 'dataMetaDom/python'
require 'dataMetaByteSer/util'

module DataMetaByteSer
# (De)Serialization for Python
module Py
    include DataMetaDom, DataMetaDom::PythonLexer, DataMetaByteSer
=begin rdoc
Builds a class name for a Writable.
=end
    def writableClassName(baseName); "#{baseName}_Writable" end
=begin rdoc
Builds a class name for a InOutable.
=end
    def inOutablePy(arg)
        klassName = case
                        when arg.kind_of?(String)
                            arg
                        else
                            _, s = DataMetaDom.splitNameSpace(arg.fType.type)
                            s
                    end
        "#{klassName}_InOutable"
    end

    def mapsNotSupported(fld)
        raise ArgumentError, "Field #{fld.name}: maps are not currently supported on Hadoop layer"
    end

    def aggrNotSupported(fld, forWhat)
        raise ArgumentError, "Field #{fld.name}: aggregate types are not supported for #{forWhat} on Hadoop layer"
    end

=begin rdoc
HDFS Reader and Writer for textual Python types such as str.
=end
    TEXT_RW_METHODS = DataMetaByteSer::RwHolder.new(
            lambda{|ctx|
                ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}String(di)") : ctx.rw.call('DataMetaHadoopUtil.readText(di)')
            },
            lambda{|ctx|
                ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}String(do, val.#{ctx.valGetter})" : "DataMetaHadoopUtil.writeTextIfAny(do, val.#{ctx.valGetter})"
            }
    )

=begin rdoc
HDFS Reader and Writer for integral Python type.
=end
        INTEGRAL_RW_METHODS = RwHolder.new(
                lambda{ |ctx|
                    mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                    case
                        when ctx.fType.length <= 4; ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}Integer(di)") :
                                ctx.rw.call('WritableUtils.readVInt(di)')

                        when ctx.fType.length <= 8; ; ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}Long(di)") : ctx.rw.call('WritableUtils.readVLong(di)')

                        else; raise "Invalid integer field #{ctx.fld}"
                    end
                },
                lambda{ |ctx|
                    case
                        when ctx.fType.length <= 4; ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}Integer(do, val.#{ctx.valGetter})" :
                                "WritableUtils.writeVInt(do, val.#{ctx.valGetter})"

                        when ctx.fType.length <= 8;  ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}Long(do, val.#{ctx.valGetter})" : "WritableUtils.writeVLong(do, val.#{ctx.valGetter})"

                        else; raise "Invalid integer field #{ctx.fld}"
                    end
                })

=begin rdoc
HDFS Reader and Writer for Booleans.
=end
    BOOLEAN_RW_METHODS = RwHolder.new(
            lambda{|ctx|
                mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}Boolean(di)") : ctx.rw.call('di.readBoolean()')
            },
            lambda{|ctx|
                mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}Boolean(do, val.#{ctx.valGetter})" : "do.writeBoolean(val.#{ctx.valGetter})"
            })

    # Python has no primitivable types
    PRIMITIVABLE_TYPES = Set.new

=begin rdoc
HDFS Reader and Writer for floating point types.
=end
        FLOAT_RW_METHODS = RwHolder.new(
                lambda{|ctx|
                    mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                    case
                        when ctx.fType.length <= 4; ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}Float(di)") : ctx.rw.call('di.readFloat()')
                        when ctx.fType.length <= 8; ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}Double(di)") : ctx.rw.call('di.readDouble()')
                        else; raise "Invalid float field #{ctx.fld}"
                    end
                },
                lambda{|ctx|
                    mapsNotSupported(ctx.fld) if ctx.fld.trgType # map
                    case
                        when ctx.fType.length <= 4; ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}Float(do, val.#{ctx.valGetter})" : "do.writeFloat(val.#{ctx.valGetter})"
                        when ctx.fType.length <= 8; ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}Double(do, val.#{ctx.valGetter})" : "do.writeDouble(val.#{ctx.valGetter})"
                        else; raise "Invalid float field #{ctx.fld}"
                    end
                })

=begin rdoc
HDFS Reader and Writer for the temporal type, the DateTime
=end
        DTTM_RW_METHODS = RwHolder.new(
                lambda { |ctx|
                    ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}DateTime(di)") : ctx.rw.call('DataMetaHadoopUtil.readDttm(di)')
                },
                lambda { |ctx|
                    ctx.fld.aggr ? "DataMetaHadoopUtil.write#{aggrPyFull(ctx.fld.aggr)}DateTime(do, val.#{ctx.valGetter})" : "DataMetaHadoopUtil.writeDttm(do, val.#{ctx.valGetter})"
                }
        )
=begin rdoc
HDFS Reader and Writer the variable size Decimal data type.
=end
        NUMERIC_RW_METHODS = RwHolder.new(lambda{|ctx| ctx.fld.aggr ? ctx.rw.call("DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}BigDecimal(di)") : ctx.rw.call('DataMetaHadoopUtil.readBigDecimal(di)')},
                                          lambda{|ctx| "DataMetaHadoopUtil.writeBigDecimal(do, val.#{ctx.valGetter})"})

# Full name of a Py aggregate for the given DataMeta DOM aggregate
    def aggrPyFull(aggr)
        case aggr
            when DataMetaDom::Field::LIST
                'List'
            when DataMetaDom::Field::SET
                'Set'
            when DataMetaDom::Field::DEQUE
                'Deque' # note this is different from Java
            else
                raise ArgumentError, "Aggregate type #{aggr} not supported for Python serialization"
        end
    end

=begin rdoc
HDFS Reader and Writer the Java Enums.
=end
        ENUM_RW_METHODS = RwHolder.new(
                lambda{|ctx|
                    aggrNotSupported(ctx.fld, 'Enums') if ctx.fld.aggr
                    _, s = DataMetaDom.splitNameSpace(ctx.fType.type)
                    "#{s}(WritableUtils.readVInt(di) + 1)" # Python starts their enums from 1 - we save it starting from 0
                    # as Java and Scala does
                },
                lambda { |ctx|
                    aggrNotSupported(ctx.fld, 'Enums') if ctx.fld.aggr
                    # Python starts their enums from 1 - we save it starting from 0 as Java and Scala
                    "WritableUtils.writeVInt(do, val.#{ctx.valGetter}.value - 1)"
                }
        )
=begin rdoc
HDFS Reader and Writer the URL.
=end
        URL_RW_METHODS = RwHolder.new(
                lambda { |ctx|
                    aggrNotSupported(ctx.fld, 'URLs') if ctx.fld.aggr
                    'DataMetaHadoopUtil.readText(di)'
                },
                lambda { |ctx|
                    aggrNotSupported(ctx.fld, 'URLs') if ctx.fld.aggr
                    "DataMetaHadoopUtil.writeTextIfAny(do, val.#{ctx.valGetter})"
                }
        )
# Pseudo-implementers that just raise an error
    NOT_IMPLEMENTED_METHODS = RwHolder.new(
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Serialization')
            },
            lambda { |ctx|
                aggrNotSupported(ctx.fld, 'Serialization')
            }
    )
=begin rdoc
Read/write methods for the standard data types.
=end
        STD_RW_METHODS = {
                DataMetaDom::INT => INTEGRAL_RW_METHODS,
                DataMetaDom::STRING => TEXT_RW_METHODS,
                DataMetaDom::DATETIME => DTTM_RW_METHODS,
                DataMetaDom::BOOL => BOOLEAN_RW_METHODS,
                DataMetaDom::CHAR => TEXT_RW_METHODS,
                DataMetaDom::FLOAT => FLOAT_RW_METHODS,
                DataMetaDom::RAW => NOT_IMPLEMENTED_METHODS,
                DataMetaDom::NUMERIC => NUMERIC_RW_METHODS,
                DataMetaDom::URL => URL_RW_METHODS
        }
# DataMeta DOM object renderer
        RECORD_RW_METHODS = RwHolder.new(
                lambda { |ctx|
                    if ctx.fld.aggr
                        if ctx.fld.trgType # map
                            mapsNotSupported(ctx.fld)
                        else  # list, set or deque
                            "DataMetaHadoopUtil.read#{aggrPyFull(ctx.fld.aggr)}(di, #{
                            inOutablePy(ctx)}())"
                        end
                    else # scalar
                        "#{inOutablePy(ctx)}().read(di)"
                    end
                },
                lambda { |ctx|
                    if ctx.fld.aggr && !ctx.fld.trgType
                        if ctx.fld.trgType # map
                            mapsNotSupported(ctx.fld)
                        else  # list, set or deque
                            "DataMetaHadoopUtil.writeCollection(val.#{ctx.valGetter}, do, #{inOutablePy(ctx)}())"
                        end
                    else # scalar
                        "#{inOutablePy(ctx)}().write(do, val.#{ctx.valGetter})"
                    end
                }
        )
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
                    NOT_IMPLEMENTED_METHODS
                when ctx.refType.kind_of?(DataMetaDom::Mapping)
                    MAP_RW_METHODS[ctx.fType.type] || (raise ArgumentError, "No renderer found for the key type #{
                    ctx.fType.type}, record #{ctx.rec}, field #{ctx.fld}")
                else
                    raise "No renderer defined for field #{ctx.fld}"
            end
        end

# Generates one InOutable, Writables here currently are not generated
        def genWritable(model, wriOut, ioOut, record, pyPackage, baseName)
            enumCount = model.enums.values.select{|e| e.kind_of?(DataMetaDom::Enum)}.size
            recImports = model.records.values.map{|r| # import all records
                p, b, pp = DataMetaDom::PojoLexer::assertNamespace(r.name)
                %|from #{DataMetaXtra::Str.downCaseFirst(b)} import #{b}|
            }.join("\n")
#             ioImports = model.records.values.reject{|r| r.name == record.name}.map{|r| # import all InOutables except of this one
#                 p, b, pp = DataMetaDom::PojoLexer::assertNamespace(r.name)
#                 # since one InOutable may import another which may import another, and Python can't handle this,
#                 # catch the error. It's harmless because if it really failed to import, we'll know
#                 %|
# try:
#     from #{inOutablePy(DataMetaXtra::Str.downCaseFirst(b))} import #{inOutablePy(b)}
# except ImportError:
#     pass|
#             }.join("\n")
            ctx = RendCtx.new.init(model, record, pyPackage, baseName)
            fields = record.fields
            wriName = nil # writableClassName(baseName)
            ioName = inOutablePy(baseName)
            hasOptional = fields.values.map{|f|
#      !model.records[f.dataType.type] &&
                !f.isRequired
            }.reduce(:|) # true if there is at least one optional field which isn't a record
            keysInOrder = fields.each_key.map{|k| k.to_s}.sort.map{|k| k.to_sym}
            reads = ''
            writes = ''
            writeNullMaskHead = hasOptional ? "nullFlags = bitarray(#{fields.keys.size}); nullFlags.setall(False); fldIndex = -1" : ''
            readNullMaskHead = hasOptional ? 'nullFlags = DataMetaHadoopUtil.readBitArray(di); fldIndex = -1' : ''
            indent = "\n#{' ' * 8}"
            # sorting provides predictable read/write order
            keysInOrder.each { |k|
                f = fields[k]
                ctx.fld = f
                rwRenderer = getRwRenderer(ctx)
                reads <<  ( indent + (f.isRequired ? '' : "fldIndex += 1#{indent}") + "val.#{DataMetaDom.setterName(ctx.fld)}(" +
                        (f.isRequired ? '' : ' None if nullFlags[fldIndex] else ')+ "#{rwRenderer.r.call(ctx)})"
                )
                # noinspection RubyNestedTernaryOperatorsInspection
                writes << (indent + (f.isRequired ?
                        (PRIMITIVABLE_TYPES.member?(f.dataType.type) ? '' : ''):
#%Q<if(val.#{DataMetaDom::PojoLexer::getterName(ctx.fld)}() == null) throw noReqFld("#{f.name}"); >) :
                        "if(val.#{DataMetaDom.getterName(ctx.fld)}() is not None): ") + "#{rwRenderer.w.call(ctx)}")
                unless f.isRequired
                    writeNullMaskHead << (indent + "fldIndex += 1#{indent}if(val.#{DataMetaDom.getterName(ctx.fld)}() is None): nullFlags[fldIndex] = True")
                end
            }
            writeNullMaskHead << ( indent + 'DataMetaHadoopUtil.writeBitArray(do, nullFlags)') if hasOptional

            ioOut.puts <<IN_OUTABLE_CLASS

class #{ioName}(InOutable):

    def write(self, do, val):
        val.verify()
        #{writeNullMaskHead}
        #{writes}

    def readVal(self, di, val):
        #{readNullMaskHead}
        #{reads}
        return val

    def read(self, di):
        return self.readVal(di, #{baseName}())

IN_OUTABLE_CLASS
        end

=begin rdoc
Generates all the writables for the given model.
Parameters:
* +model+ - the model to generate Writables from.
* +outRoot+ - destination directory name.
=end
        def genWritables(model, outRoot)
            firstRecord = model.records.values.first
            pyPackage, base, packagePath = DataMetaDom::PojoLexer::assertNamespace(firstRecord.name)
            # Next: replace dots with underscores.The path also adjusted accordingly.
            #
            # Rationale for this, quoting PEP 8:
            #
            #    Package and Module Names
            #
            #    Modules should have short, all-lowercase names. Underscores can be used in the module name if it improves
            #    readability. Python packages should also have short, all-lowercase names, although the use of underscores
            #    is discouraged.
            #
            # Short and all-lowercase names, and improving readability if you have complex system and need long package names,
            # is "discouraged". Can't do this here, our system is more complicated for strictly religous, "pythonic" Python.
            # A tool must be enabling, and in this case, this irrational ruling gets in the way.
            # And dots are a no-no, Python can't find packages with complicated package structures and imports.
            #
            # Hence, we opt for long package names with underscores for distinctiveness and readability:
            pyPackage = pyPackage.gsub('.', '_')
            packagePath = packagePath.gsub('/', '_')
            destDir = File.join(outRoot, packagePath)
            FileUtils.mkdir_p destDir
            wriOut = nil # File.open(File.join(destDir, "#{writableClassName(base)}.py"), 'wb')
            serFile = File.join(destDir, 'serial.py')
            FileUtils.rm serFile if File.file?(serFile)
            ioOut = File.open(serFile, 'wb') # one huge serialization file
            ioOut.puts %|# This file is generated by DataMeta DOM. Do not edit manually!
#package #{pyPackage}

from hadoop.io import WritableUtils, InputStream, OutputStream, Text
from ebay_datameta_core.base import DateTime
from decimal import *
from collections import *
from bitarray import bitarray
from ebay_datameta_hadoop.base import *
from model import *

|
            begin
                model.records.values.each { |e|
                        _, base, _ = DataMetaDom::PojoLexer::assertNamespace(e.name)
                        case
                            when e.kind_of?(DataMetaDom::Record)
                                genWritable model, wriOut, ioOut, e, pyPackage, base
                            else
                                raise "Unsupported Entity: #{e.inspect}"
                        end
                }
            ensure
                begin
                    ioOut.close
                ensure
                    #wriOut.close
                end
            end
        end
        module_function :genWritables, :genWritable, :inOutablePy, :writableClassName, :mapsNotSupported,
            :aggrNotSupported, :getRwRenderer, :aggrPyFull
end
end
