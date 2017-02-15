$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'erb'
require 'fileutils'
require 'dataMetaDom'
require 'dataMetaDom/help'
require 'dataMetaDom/pojo'
require 'dataMetaDom/record'
require 'dataMetaDom/util'
require 'ostruct'

=begin rdoc
DataMetaDOM and {Avro}[http://avro.apache.org/docs/current] {Schemas}[http://avro.apache.org/docs/current/spec.html].

For command line details either check the new method's source or the README, the usage section.
=end

module DataMetaAvro
    # Current version
    VERSION = '1.0.0'

    # The root of the gem.
    GEM_ROOT = File.realpath(File.dirname(__FILE__) + '/../')

    # Location of templates.
    TMPL_ROOT = File.join(GEM_ROOT, 'tmpl')

=begin rdoc
Mapping from a DataMeta DOM type to a matching renderer of Avro schema JSON.
The lambda expect whole DataMetaDom::Field instance, must return the whole
specification that you would put under the <tt>"type":</tt> JSON tag, such as:
    "int"
or, for a type with a size:
    { "type": "fixed", "name": "theFieldName", "size": 16}

Note that wrapping this type into optional specification, i.e. unioned with <tt>"null"</tt> is done by calling
the avroType method.
=end
    AVRO_TYPES = {
            DataMetaDom::BOOL => lambda{|dt| %q<"boolean">},
            DataMetaDom::INT => lambda{ |dt|
              len = dt.length
              case
                when len <= 4; %q<"int">
                when len <= 8; %q<"long">
                else; raise "Invalid integer length #{len}"
              end
            },
            DataMetaDom::FLOAT => lambda{|dt|
              len = dt.length
              case
                when len <= 4; %q<"float">
                when len <= 8; %q<"double">
                else; raise "Invalid float length #{len}"
              end
            },
            DataMetaDom::RAW => lambda{|dt| %q<"bytes">},
            DataMetaDom::STRING => lambda{|dt| %q<"string">},
=begin
Unlike DataMeta DOM, Avro does not support temporal types such as date, time and datetime,
they have a ticket filed for it but no idea when it is going to be implemented.
They use {integral types}[http://avro.apache.org/docs/current/spec.html#Time+%28millisecond+precision%29] for
everything temporal.
=end
        DataMetaDom::DATETIME => lambda{|dt| %q<"long">},
# No support for these in this release:
          #NUMERIC => lambda{|t| "BigDecimal"}
    }

=begin rdoc
Converts DataMeta DOM type to Avro schema type.
=end
    def avroType(dataMetaType)
        renderer = AVRO_TYPES[dataMetaType.type]
        raise "Unsupported type #{dataMetaType}" unless renderer
        renderer.call(dataMetaType)
    end

# Wraps required/optional in proper enclosure
    def wrapReqOptional(field, baseType)
        field.isRequired ? baseType : %Q^[#{baseType}, "null"]^
    end

=begin rdoc
Generates an {Avro Schema}[http://avro.apache.org/docs/current/spec.html] for the given model's record.

It makes impression that some parameters are not used, but it is not so: they are used by the ERB template
as the part of the method's binding.

The parameters nameSpace and the base can be derived from rec, but since they are evaluated previously by calling
assertNamespace, can just as well reuse them.

* Params:
  * model - DataMetaDom::Model
  * outFile - output file name
  * rec - DataMetaDom::Record
  * nameSpace - the namespace for the record
  * base - base name of the record
=end
    def genRecordJson(model, outFile, rec, nameSpace, base)
        vars =  OpenStruct.new # for template's local variables. ERB does not make them visible to the binding
        IO.write(outFile, "#{ERB.new(IO.read("#{TMPL_ROOT}/dataClass.avsc.erb"), 0, '-').result(binding)}", {:mode => 'wb'})
    end

=begin rdoc
Splits the full name of a class into the namespace and the base, returns an array of
the namespace (empty string if there is no namespace on the name) and the base name.

Examples:
* <tt>'BaseNameAlone'</tt> -> <tt>['', 'BaseNameAlone']</tt>
* <tt>'one.package.another.pack.FinallyTheName'</tt> -> <tt>['one.package.another.pack', 'FinallyTheName']</tt>
=end
    def assertNamespace(fullName)
      ns, base = DataMetaDom::splitNameSpace(fullName)
      [DataMetaDom.validNs?(ns, base) ? ns : '', base]
    end

=begin rdoc
Generates the {Avro Schema}[http://avro.apache.org/docs/current/spec.html], one +avsc+ file per a record.
=end
    def genSchema(model, outRoot)
      model.records.values.each { |rec| # loop through all the records in the model
        nameSpace, base = assertNamespace(rec.name)
        FileUtils.mkdir_p outRoot # write json files named as one.package.another.package.ClassName.json in one dir
        outFile = File.join(outRoot, "#{rec.name}.avsc")
          case
            when rec.kind_of?(DataMetaDom::Record)
                genRecordJson model, outFile, rec, nameSpace, base
            else # since we are cycling through records, should never get here
              raise "Unsupported Entity: #{rec.inspect}"
          end
      }
    end

    # Shortcut to help for the Hadoop Writables generator.
    def helpAvroSchemaGen(file, errorText=nil)
        DataMetaDom::help(file, "DataMeta DOM Avro Schema Generation ver #{VERSION}",
                          '<DataMeta DOM source> <Avro Schemas target dir>', errorText)
    end

    def assertMapKeyType(fld, type)
        raise ArgumentError, %<Field "#{fld.name}": Avro supports only strings as map keys, "#{
            type}" is not supported as a map key by Avro> unless type == DataMetaDom::STRING
    end
module_function :helpAvroSchemaGen, :genSchema, :assertNamespace, :genRecordJson, :avroType, :assertMapKeyType,
            :wrapReqOptional
end
