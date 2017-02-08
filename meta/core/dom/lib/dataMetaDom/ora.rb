$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set).each { |r| require r }

module DataMetaDom

=begin rdoc
Definition for generating Oracle 11 and later artifacts such as schemas, select statements,
ORM input files etc etc

TODO this isn't a bad way, but beter use templating next time such as {ERB}[http://ruby-doc.org/stdlib-1.9.3/libdoc/erb/rdoc/ERB.html].

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
module OraLexer

=begin rdoc
Integer types
=end
    INT_TYPES = {2 => 'number(6)', 4 => 'number(9)', 8 => 'number(38)'}

=begin rdoc
Not null (required) wording per Oracle DDL syntax
=end
    NOT_NULL=' not null'

=begin rdoc
\Mapping from DataMeta DOM standard types to correspondent Oracle types renderer lambdas.
=end
    SQL_TYPES={
            INT => lambda { |len, scale, isReq|
                concreteType = INT_TYPES[len]
                raise "Invalid integer type length #{len} " unless concreteType
                "#{concreteType}#{isReq ? NOT_NULL : ''}"
            },
            STRING => lambda { |len, scale, isReq| "nvarchar2(#{len})#{isReq ? NOT_NULL : ''}" },
            DATETIME => lambda { |len, scale, isReq| "timestamp#{isReq ? NOT_NULL : ''}" },
            # Boolean implementation in Oracle is not optimal, see the doc:
            # http://docs.oracle.com/cd/B19306_01/olap.102/b14346/dml_datatypes004.htm
            BOOL => lambda { |len, scale, isReq| "boolean#{isReq ? NOT_NULL : ''}" },
            CHAR => ->(len, scale, isReq) { "nchar(#{len})#{isReq ? NOT_NULL : ''}" },
            NUMERIC => ->(len, scale, isReq) { "number(#{len}, #{scale})#{isReq ? NOT_NULL : ''}" }

    }

=begin rdoc
Encapsulates 4 parts of DDL related SQL output:
* Creates
* Drops
* Linking aka Coupling aka creating Foreign Keys
* Unlinking aka Uncoupling aka dropping Foreign Keys
=end
    class SqlOutput

=begin rdoc
Open output file into create SQL DDL statements (CREATE TABLE)
=end
        attr_reader :create

=begin rdoc
Open output file into drop SQL DDL statements (DROP TABLE)
=end
        attr_reader :drop

=begin rdoc
Open output file into the \couple SQL DDL statements, creating foreign keys
=end
        attr_reader :couple
=begin rdoc
Open output file into the \uncouple SQL DDL statements, dropping foreign keys
=end
        attr_reader :uncouple
=begin rdoc
Sequences and triggers - create
=end
        attr_reader :crSeqs
=begin rdoc
Sequences and triggers - drop
=end
        attr_reader :drSeqs
=begin rdoc
Indexes
=end
        attr_reader :ixes


=begin rdoc
Creates an instance into the given target directory in which all 4 parts of the SQL DDL
process will be created.
=end
        def initialize(sqlTargetDir)
            @selTargetDir = sqlTargetDir
            @create = File.new("#{sqlTargetDir}/DDL-createTables.sql", 'wb')
            @crSeqs = File.new("#{sqlTargetDir}/DDL-createSeqs.sql", 'wb')
            @drSeqs = File.new("#{sqlTargetDir}/DDL-dropSeqs.sql", 'wb')
            @ixes = File.new("#{sqlTargetDir}/DDL-indexes.sql", 'wb')
            @drop = File.new("#{sqlTargetDir}/DDL-drop.sql", 'wb')
            @couple = File.new("#{sqlTargetDir}/DDL-couple.sql", 'wb')
            @uncouple = File.new("#{sqlTargetDir}/DDL-uncouple.sql", 'wb')
            @allScriptFiles = [@create, @drop, @couple, @uncouple, @drSeqs, @crSeqs, @ixes]
            @dropScripts = [@uncouple, @drop]
            @allScriptFiles.each { |f|
                f.puts %q</* Generated by DataMeta DOM Oracle utility
DO NOT EDIT MANUALLY, update the DataMeta DOM source and regen.
*/
>
            }
            @dropScripts.each { |ds|
                ds.puts %q<
/* Oracle does not have this feature: Disable all checks for safe dropping without any errors */

>
            }
        end

=begin rdoc
Safely closes all the output files.
=end
        def close
            @dropScripts.each { |ds|
                ds.puts %q<

/* Placeholder for a drop footer */
>
            }
            @allScriptFiles.each { |f|
                begin
                    f.close
                rescue Exception => x;
                    $stderr.puts x.message
                end
            }
        end
    end

=begin rdoc
Renders autoincrement the very special Oracle way, via a sequence
FIXME: need to check the auto hint

@return empty string
=end
    def autoGenClauseIfAny(out, record, field)
        if record.identity && record.identity.length == 1 && field.name == record.identity[0] &&
                field.dataType.type == DataMetaDom::INT
            ns, entityName = DataMetaDom.splitNameSpace record.name
            seqName = "#{entityName}_#{field.name}_sq"
# Transaction separators are important for triggers and sequences
            out.crSeqs.puts %|
CREATE SEQUENCE #{seqName};

/
|
=begin rdoc
 To make the sequence used automatically:
CREATE OR REPLACE TRIGGER #{entityName}_#{field.name}_trg
BEFORE INSERT ON #{entityName}
FOR EACH ROW

BEGIN
  SELECT #{seqName}.NEXTVAL
  INTO   :new.#{field.name}
  FROM   dual;
END;
=end
            out.drSeqs.puts %|

drop SEQUENCE #{seqName};
/
|
        end

        ''
    end

=begin rdoc
Renders the given field into create statement.
* Parameters:
  * +createStatement+ - the create statement to append the field definition to.
  * +parser+ - the instance of the Model
  * +record+ - the instance of the Record to which the field belongs
  * +fieldKey+ - the full name of the field to render turned into a symbol.
  * +isFirstField+ - the boolean, true if the field is first in the create statement.
=end
    def renderField(out, createStatement, parser, record, fieldKey, isFirstField)
        field = record[fieldKey]
        ty = field.dataType
        stdRenderer = SQL_TYPES[ty.type]
        typeEnum = parser.enums[ty.type]
        typeRec = parser.records[ty.type]

        typeDef = if stdRenderer
                      stdRenderer.call ty.length, ty.scale, field.isRequired
                  elsif typeEnum
                      "enum('#{typeEnum.values.join("','")}')"
                  elsif typeRec
                      raise "Invalid ref to #{typeRec} - it has no singular ID" unless typeRec.identity.length == 1
                      idField = typeRec[typeRec.identity[0]]
                      idRenderer = SQL_TYPES[idField.dataType.type]
                      raise 'Only one-level prim type references only allowed in this version' unless idRenderer
                      idRenderer.call idField.dataType.length, idField.dataType.scale, field.isRequired
                  end
        createStatement << ",\n" unless isFirstField
        createStatement << "\t#{field.name} #{typeDef}#{autoGenClauseIfAny(out, record, field)}"
    end

=begin rdoc
Builds and returns the foreign key name for the given entity (Record) name and the counting number of these.
* Parameters:
  * +bareEntityName+ - the entity name without the namespace
  * +index+ - an integer, an enumerated counting number, starting from one. For each subsequent FK this number is
    incremented.
=end
    def fkName(bareEntityName, index)
        "fk_#{bareEntityName}_#{index}"
    end

=begin rdoc
Render SQL record with for the given model into the given output.
* Parameters
  * +out+ - an instance of SqlOutput
  * +parser+ - an instance of Model
  * +recordKey+ - full name of the record datatype including namespeace if any turned into a symbol.
=end
    def renderRecord(out, parser, recordKey)
        record = parser.records[recordKey]
        ns, entityName = DataMetaDom.splitNameSpace record.name
        isFirstField = true
        # Oracle does not have neatly defined feature of dropping table if it exists
        # https://community.oracle.com/thread/2421779?tstart=0
        out.drop.puts %|\ndrop table #{entityName};
/
|
        fkNumber = 1 # to generate unique names that fit in 64 characters of identifier max length for Oracle
        record.refs.select { |r| r.type == Reference::RECORD }.each { |ref|
            ns, fromEntityBareName = DataMetaDom.splitNameSpace ref.fromEntity.name
            ns, toEntityBareName = DataMetaDom.splitNameSpace ref.toEntity.name
            out.couple.puts "alter table #{fromEntityBareName} add constraint #{fkName(fromEntityBareName, fkNumber)} "\
  " foreign key (#{ref.fromField.name}) references #{toEntityBareName}(#{ref.toFields.name});"
            out.uncouple.puts "alter table #{fromEntityBareName} drop foreign key #{fkName(fromEntityBareName, fkNumber)};"
            fkNumber += 1
        }
        ids = record.identity ? record.identity.args : []
        createStatement = "create table #{entityName} (\n"
        fieldKeys = [] << ids.map { |i| i.to_s }.sort.map { |i| i.to_sym } \
   << record.fields.keys.select { |k| !ids.include?(k) }.map { |k| k.to_s }.sort.map { |k| k.to_sym }

        fieldKeys.flatten.each { |f|
            renderField(out, createStatement, parser, record, f, isFirstField)
            isFirstField = false
        }
        if record.identity && record.identity.length > 0
            createStatement << ",\n\tprimary key(#{ids.sort.join(', ')})"
        end
        unless record.uniques.empty?
            uqNumber = 1
            record.uniques.each_value { |uq|
                createStatement << ",\n\tconstraint uq_#{entityName}_#{uqNumber} unique(#{uq.args.join(', ')})"
                uqNumber += 1 # to generate unique names that fit in 30 characters of identifier max length for Oracle
            }
        end
        unless record.indexes.empty?
            ixNumber = 1
            record.indexes.each_value { |ix|
                out.ixes.puts %|
CREATE INDEX #{entityName}_#{ixNumber} ON #{entityName}(#{ix.args.join(', ')});
/
|
#                createStatement << ",\n\tindex ix_#{entityName}_#{ixNumber}(#{ix.args.join(', ')})"
                ixNumber += 1 # to generate unique names that fit in 64 characters of identifier max length for Oracle
            }
        end
        createStatement << "\n);\n/\n"

        out.create.puts createStatement
    end

=begin rdoc
Generate the Oracle DDL from the given Model into the given output directory.
* Parameters
  * +parser+ - an instance of a Model
  * +outDir+ - a String, the directory to generate the DDL into.
=end
    def genDdl(parser, outDir)
        out = SqlOutput.new(outDir)
        begin
            parser.records.each_key { |r|
                renderRecord(out, parser, r)
            }
        ensure
            out.close
        end
    end

end
end
