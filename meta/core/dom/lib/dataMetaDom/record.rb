$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set dataMetaXtra dataMetaDom/docs dataMetaDom/ver).each { |r| require r }

module DataMetaDom

=begin rdoc
A mapping - of values from one data type to values of another data types. Supports only DataMeta DOM standard types

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Mapping < VerDoccable

    # Empty binding for evaluation to avoid exposing class variables
    BINDING_NONE = DataMetaXtra.nilBinding

=begin rdoc
Name of this mapping data type including namespace if any.
=end
    attr_accessor :name
=begin rdoc
DataType "from" (source)
=end
    attr_accessor :fromT
=begin rdoc
DataType "to" (target)
=end
    attr_accessor :toT

=begin rdoc
The hash of the "from" (source) values to the "to" (target) values.
=end
    attr_accessor :base

=begin rdoc
Creates an instance for the given full data type name, including namespace if any.
=end
    def initialize(name)
        #noinspection RubyArgCount
        super()
        @name = name.to_sym; @base = {}
    end

=begin rdoc
Returns the value for the given key as mapped.
* Parameters:
  * +key+ - the value of the type "from" (source) to get the matching value of the type "to" (target) for.
=end
    def [](key); @base[key] end

=begin rdoc
Assign the mapped value for the given key, useful for building a mapping from the code.
* Parameters:
  * +key+ - the value of the type "from" (source)
  * +val+ - the matching value of the type "to" (target).
=end
    def []=(key, val); base[key] = val end

=begin rdoc
All the values of the type "to" (target) defined on the mapping, sorted
=end
    def values; @base.values.sort end

=begin rdoc
All the keys of the type "from" (source) defined on the mapping, sorted
=end
    def keys; @base.keys.sort end

=begin rdoc
Parses the mapping, the keys and the values from the given source.
* Parameters
  * +source+ - an instance of SourceFile
=end
    def parseBase(source)
        hashSource = '{'
        while (line = source.nextLine)
            case line
                when /^\s*#{END_KW}\s*$/
                    self.ver = source.ver unless self.ver
                    self.docs = source.docs.clone
                    source.docs.clear
                    raise "Version missing for the Mapping #{name}" unless self.ver
                    break
                else
                    hashSource << line
            end # case
        end # while line
        @base = eval(hashSource + '}', BINDING_NONE)
        self
    end # def parse
end

=begin rdoc
A Bit Set mapping, one instance holding a set of references to the values packed tightly as a bit set.
=end
class BitSet < Mapping

=begin rdoc
Attempts to consume the instance from the given source, returns it if successful, returns nil otherwise.
* Parameters
  * +model+ - an instance of a Model
  * +src+ - an instance of SourceFile
=end
    def self.consumed?(model, src)
        src.line =~ /^\s*#{BITSET}\s+(\w+)\s+.+$/ ? model.addEnum(BitSet.new(combineNsBase(DataMetaDom.nsAdjustment(src.namespace, model.options, src), $1)).parse(src)) : nil
    end

=begin rdoc
Returns the keyword for this Mapping implementation, in this case "<tt>bitset</tt>"
=end
    def sourceKeyWord; BITSET end

=begin rdoc
Parses the current instance from the given source.
* Parameters
  * +src+ - an instance of SourceFile
=end
    def parse(src)
        r = src.line.scan(/^\s*\w+\s+\w+\s+(\S+)\s*$/)
        raise 'Invalid bitset specification' unless r && r[0] && r[0][0]
        self.fromT = INT4 #platform type is up to the concrete generator
        self.toT = DataType.parse(src, r[0][0])
        parseBase src
    end
end

=begin rdoc
A single-value map of a key to a value.
=end
class Mappings < Mapping

=begin rdoc
Attempts to consume the instance from the given source, returns it if successful, returns nil otherwise.
* Parameters
  * +model+ - an instance of a Model
  * +src+ - an instance of SourceFile
=end
    def self.consumed?(model, src)
        src.line =~ /^\s*#{MAPPING}\s+(\w+)\s+.+$/ ? model.addEnum(Mappings.new(combineNsBase(DataMetaDom.nsAdjustment(src.namespace, model.options, src), $1)).parse(src)) : nil
    end

=begin rdoc
Returns the keyword for this Mapping implementation, in this case "<tt>map</tt>"
=end
    def sourceKeyWord; MAPPING end

=begin rdoc
Parses the current instance from the given source.
* Parameters
  * +src+ - an instance of SourceFile
=end
    def parse(src)
        r = src.line.scan(/^\s*\w+\s+\w+\s+(\S+)\s+(\S+)\s*$/)
        raise 'Invalid map specification' unless r && r[0] && r[0][0] && r[0][1]
        self.fromT = DataType.parse(src, r[0][0])
        self.toT = DataType.parse(src, r[0][1])
        parseBase src
    end
end

=begin rdoc
A data structure comprised of fields with the notion of identity, indexes, unique and not.
@!attribute [r] namespace
    @return [String] part of the {#name}, the prefix before last dot, "package" in Java and Scala, "namespace" in C

@!attribute [r] baseName
    @return [String] part of the {#name}, the suffix after last dot

=end
class Record < VerDoccable

=begin rdoc
Full Record datatype name, including namespace if any. Should be unique in the model.
=end
    attr_accessor :name

=begin rdoc
The fields as a map keying a field name to the matching instance of a Field
=end
    attr_reader :fields

=begin rdoc
An instance of RecIdentity.
=end
    attr_reader :identity

=begin rdoc
A hash mapping to RecUnique from its key. Meaning, RecUnique.key to the matching RecUnique
=end
    attr_reader :uniques

=begin rdoc
A hash mapping to RecIndex from its key. Meaning, RecIndex.key to the matching RecIndex
=end
    attr_reader :indexes

=begin rdoc
An array of Reference
=end
    attr_reader :refs

=begin rdoc
The unique key for the record, unique across the Model.
=end
    attr_reader :key

    attr_reader :namespace

    attr_reader :baseName

=begin rdoc
Attempts to consume the instance from the given source, returns it if successful, returns nil otherwise.
* Parameters
  * +model+ - an instance of a Model
  * +src+ - an instance of SourceFile
=end
    def self.consumed?(model, src)
        if src.line =~ /^\s*#{RECORD}\s+(\w+)$/
            newRecord = Record.new(DataMetaDom.combineNsBase(DataMetaDom.nsAdjustment(src.namespace, model.options, src).to_sym, $1)).parse(model, src)
            $stderr.puts %<WARN: Record redefinition: "#{newRecord.key}"> if model.records[newRecord.key]
            model.addRecord(newRecord)
        else
            nil
        end
    end

=begin rdoc
Creates an instance for the given full data type name, including namespace.
Namespace is required.


=end
    def initialize(name)
        #noinspection RubyArgCount
        super()
        @namespace, @baseName = DataMetaDom.splitNameSpace(name)

        raise %Q<Record "#{@baseName}": no namespace; namespaces are required!> unless @namespace
        @name = name.to_sym
        @key = @name
        @fields={}; @uniques={}; @identity=nil; @indexes = {}; @refs=[]
    end

=begin rdoc
Fetches the field by the field key, i.e. Field.name
=end
    def [](fieldKey); @fields[fieldKey] end

=begin rdoc
Verifies that the list of ids is valid, meaning that there is a field with the given name on this record.
* Parameter
  * +ids+ - an array of strings, each should be a valid field name already defined on this Record.
=end
    def assertIds(ids)
        ids.each { |id|
            k = id.to_sym
            raise "Undeclared field '#{id}'" unless @fields.has_key?(k)
        }
    end

=begin rdoc
Set the identity on the Record.
* Parameter:
  * +newIdy+ - an instance of RecIdentity
=end
    def identity=(newIdy)
        raise 'There can be only one identity statement in a record' if @identity
        @identity = newIdy
        assertIds(@identity.args)
        @identity.args.each { |id|
            f = @fields[id.to_sym]

            raise ArgumentError, %|Field "#{
                id}" is made identity; no aggregate types or maps can be identity| if f.aggr? || f.map?

            raise ArgumentError, %|Optional field "#{
                id}" is made identity; only required fields may be identity| unless f.isRequired
        }
    end

=begin rdoc
Add another unique index to the record.
* Parameter:
  * +newUq+ - an instance of RecUnique to add ot this record.
=end
    def addUnique(newUq)
        assertIds(newUq.args)
        raise "Duplicate unique set declaration #{newUq}" if @uniques.has_key?(newUq.key)
        @uniques[newUq.key] = newUq
    end

=begin rdoc
Add another non-unique index to the record.
* Parameter:
  * +newIx+ - an instance of RecIndex to add to this Record
=end
    def addIndex(newIx)
        assertIds(newIx.args)
        raise "Duplicate index declaration #{newIx}" if @indexes.has_key?(newIx.key)
        @indexes[newIx.key] = newIx
    end

=begin rdoc
Add another field to this Record's definition along with the source reference if any.
* Parameters:
  * +newField+ - an instance of Field to add to this Record
  * +source+ - a reference to the SourceFile where this field has been defined, pass +nil+ if
   built from the code.
=end
    def addField(newField, model, source=nil)
        fieldKey = newField.name
        raise "Duplicate field name '#{fieldKey}' in the Record '#{@name}'" if (@fields.key?(fieldKey))
        @fields[fieldKey] = newField
        unless STANDARD_TYPES.member?(newField.dataType.type)
            ns, base = DataMetaDom.splitNameSpace(newField.dataType.type)
            newNs = DataMetaDom.nsAdjustment(ns, model.options, source)
            reRefName = "#{newNs}.#{base}".to_sym
            newField.dataType.type = reRefName # adjust the type for finding the reference again
            @refs << Reference.new(self, newField, reRefName, source ? source.snapshot : nil)
        end
    end

=begin rdoc
Add several Field definitions to this Record.
* Parameters:
  * +fields+ - an array of the instances of Field to add to this Record
=end
    def addFields(fields, model, source=nil); fields.each { |f| addField f, model, source } end

=begin rdoc
Add several non-unique indexes to the record.
* Parameter:
  * +ixs+ - an array of the instances of RecIndex to add to this Record
=end
    def addIndexes(ixs); ixs.each { |ix| addIndex ix } end

=begin rdoc
Add several unique indexes to the record.
* Parameter:
  * +uqs+ - an array of instances of RecUnique to add ot this record.
=end
    def addUniques(uqs); uqs.each { |uq| addUnique uq } end

=begin rdoc
Parse the Record from the given source into this instance.
* Parameter:
  * +source+ - an instance of SourceFile to parse from
=end
    def parse(model, source)
        while (line = source.nextLine)
            next if docConsumed?(source)
            case line
                when /^\s*#{END_KW}\s*$/
                    if source.docs
                        self.docs = source.docs.clone
                        source.docs.clear
                    end
                    self.ver = source.ver unless self.ver
                    raise "Version missing for the Record #{name}" unless self.ver
                    return self
                when ''
                    next
                else
                    isTokenConsumed = false
                    RECORD_LEVEL_TOKENS.each { |t|
                        isTokenConsumed = t.consumed? source, self
                        break if isTokenConsumed
                    }
                    unless isTokenConsumed
                        raise ArgumentError, "Record #{@name}: all field declarations must precede identity" if @identity
                        Field.consume(model, source, self)
                    end
                    resetEntity
            end # case line
        end # while line
        self # for call chaining
    end

=begin rdoc
Textual representation of this instance, with all the fields, attributes and references if any.
=end
    def to_s
        "Record{#{@name}(#{@fields.values.join(';')},uq=[#{@uniques.map { |u| '[' + u.join(',') + ']' }.join('; ')}]"\
       ";idy=[#{@identity ? @identity.args.join(',') : ''}]; refs=[#{@refs.join(',')}]}, #{self.ver}"
    end
end

=begin rdoc
DataMeta DOM source tokens on the Model level:
* Record
* Enum
* BitSet
* Map
=end
MODEL_LEVEL_TOKENS=[Record, Enum, BitSet, Mappings]

end
