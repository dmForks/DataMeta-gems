$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'set'
require 'dataMetaDom/converter'
require 'dataMetaDom/docs'
require 'dataMetaDom/field'
require 'dataMetaDom/ver'
require 'date'

module DataMetaDom
=begin rdoc
Metadata Model, including parsing.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Model
    include DataMetaDom

=begin rdoc
The instance of SourceFile currently being parsed.
=end
    attr_reader :currentSource

=begin rdoc
All sources, including the includes.
=end
    attr_reader :sources
=begin rdoc
Instances of Enum, Map and BitSet on this model, keyed by the full name including the namespace if any.
=end
    attr_reader :enums

=begin rdoc
Instances of Record on this model, keyed by the full name including the namespace if any.
=end
    attr_reader :records

=begin rdoc
Reverse references keyed by reference target names
=end
    attr_reader :reRefs
=begin
Documentation for all options is in this section.

* +autoNsVer+ - if set to True, advises a generator to append a +vN+ where +N+ is a version number to the namespace.
=end
    attr_accessor :options
# Version on the model level
    attr_accessor :ver

=begin rdoc
Creates a blank model.
=end
    def initialize() # no file name if want to build model manually
        @reRefs = Hash.new(*[]) # references to the entity, hash keyed by entity
        @enums={}; @records = {}
        @ver = nil
    end

=begin rdoc
Resolves references after parsing all the sources to the types that were used before than they
were defined. Verifies integrity.
=end
    def resolveVerify
        duplicateGuard = {}
        @records.each_key { |recKey|
            rec = @records[recKey]
            rec.refs.each { |ref|
                ref.resolve self
                preExisting = duplicateGuard[ref.key]
                raise "Duplicate reference spec: #{r}(#{r.sourceRef}), pre-existing: #{preExisting}(#{preExisting.sourceRef})" if preExisting
                duplicateGuard[ref.key] = ref
                reKey = ref.toEntity.name
                @reRefs[reKey] = [] unless @reRefs[reKey]
                @reRefs[reKey] << ref
            }
        }
        self
    end

=begin rdoc
Builds diagnostics string, including the source info.
=end
    def diagn; "; Src: #{@currentSource ? @currentSource : '<no source>'}" end

    # master parse, initializes process queue and seeds it with the master file
    def parse(fileName, options={autoVerNs: false})
        @options = options
        @sources = Sources.new(fileName)
        while (@currentSource=@sources.next)
            @currentSource.parse self
        end
        resolveVerify
        self
    end

=begin rdoc
Adds the given record to the model
* Parameter
  * +rec+ - instance of a Record
=end
    def addRecord(rec); @records[rec.key] = rec end

=begin rdoc
Adds the given records to the model
* Parameter
  * +recs+ - an array of instances of a Record
=end
    def addRecords(recs); recs.each { |r| addRecord r } end

=begin rdoc
Adds the given enum to the model
* Parameter
  * +rec+ - instance of a Enum or a BitSet or a Map
=end
    def addEnum(newEnum); @enums[newEnum.name] = newEnum end

=begin rdoc
Adds the given enums to the model
* Parameter
  * +rec+ - an array of instances of a Enum or a BitSet or a Map
=end
    def addEnums(enums); enums.each { |e| addEnum e } end

=begin rdoc
Generates DataMeta DOM source for the given Enum, yielding the lines to the caller's block.

* Parameters
  * +e+ - instance of a Enum or a BitSet or a Map to generate the DataMeta DOM source for
  * +baseName+ - the base name excluding the namespace if any, usually available on the caller's side.
=end
    def genSourceEnum(e, baseName)
        yield '' # yield empty line before a type

        case
            when e.kind_of?(Enum)
                if e.docs
                    genDocs(e.docs){|line| yield line}
                end
                yield "#{e.sourceKeyWord} #{baseName}"
                #genVer(e) { |line| yield line }
                e.values.each { |v|
                    yield "#{SOURCE_INDENT}#{v}"
                }
            when e.kind_of?(BitSet), e.kind_of?(Mappings)
                if e.docs
                    genDocs(e.docs){|line| yield line}
                end
                yield "#{e.sourceKeyWord} #{baseName} #{e.kind_of?(BitSet) ? '' : e.fromT.to_s + ' '}#{e.toT}"
                #genVer(e) { |line| yield line }
                e.keys.each { |k|
                    fromConv = CONVS[e.fromT.type]
                    toConv = CONVS[e.toT.type]
                    #DataMetaDom::L.debug "k=#{k.inspect}, e=#{e[k].inspect}"
                    raise "Invalid convertor for #{e}: (#{fromConv.inspect} => #{toConv.inspect})" unless fromConv && toConv
                    yield "#{SOURCE_INDENT}#{fromConv.ser.call(k)} => #{toConv.ser.call(e[k])},"
                }
            else
                raise "Enum #{e} - unsupported format"
        end
        yield END_KW
    end

=begin rdoc
Renders the source for the docs property of Documentable.
=end
    def genDocs(docs)
        docs.each_key{ |t|
            yield "#{DOC} #{t}"
            d = docs[t]
            yield d.text
            yield END_KW
        }
    end

=begin rdoc
Renders the source for the docs property of Ver.
=end
    def genVer(e)
        raise "No version on #{e}" unless e.ver
        v = e.ver
        raise "Version on #{e} is wrong type: #{v.inspect}" unless v.kind_of?(Ver)
        yield "#{VER_KW} #{v.full}"
    end

=begin rdoc
Generates DataMeta DOM source for the given Record, yielding the lines to the caller's block.

* Parameters
  * +r+ - instance of a Record to generate the DataMeta DOM source for
  * +namespace+ - the namespace of the record, usually available on the caller's side.
  * +baseName+ - the base name excluding the namespace if any, usually available on the caller's side.
=end
    def genSourceRec(r, namespace, baseName)
        yield '' # yield empty line before a type
        if r.docs
            genDocs(r.docs){|line| yield line}
        end

        yield "#{RECORD} #{baseName}"
        #genVer(r) { |line| yield line }
        r.fields.values.each { |f|
            if f.docs
                genDocs(f.docs) { |line| yield line}
            end
            t = f.dataType
            #puts ">>F: #{f}, ns=#{ns}, base=#{base}, bn=#{baseName}"
            # render names from other namespaces than the current in full
            renderType = qualName(namespace, t.type)
            srcLine = if f.map?
                          trgRender = qualName(namespace, f.trgType.type)
                          "#{SOURCE_INDENT}#{f.req_spec}#{Field::MAP}{#{renderType}#{t.length_spec}, #{trgRender}#{
                                f.trgType.length_spec}} #{f.name}#{f.default_spec}"
                      elsif f.aggr?
                          "#{SOURCE_INDENT}#{f.req_spec}#{f.aggr}{#{renderType}#{t.length_spec}} #{f.name}#{f.default_spec}"
                      else
                          "#{SOURCE_INDENT}#{f.req_spec}#{renderType}#{t.length_spec} #{f.name}#{f.default_spec}#{f.matches_spec}"
                      end
            yield  srcLine
        }

        yield "#{SOURCE_INDENT}#{IDENTITY}#{r.identity.hints.empty? ? '' : "(#{r.identity.hints.to_a.join(', ')})"} "\
          "#{r.identity.args.join(', ')}" if r.identity
        if r.uniques
            r.uniques.each_value { |uq|
                yield "#{SOURCE_INDENT}#{UNIQUE}#{uq.hints.empty? ? '' : "(#{uq.hints.to_a.join(', ')})"} #{uq.args.join(', ')}"
            }
        end
        if r.indexes
            r.indexes.each_value { |ix|
                yield "#{SOURCE_INDENT}#{INDEX}#{ix.hints.empty? ? '' : "(#{ix.hints.to_a.join(', ')})"} #{ix.args.join(', ')}"
            }
        end
        if r.refs
            r.refs.each { |ref|
                yield "# #{ref}"
            }
        end
        yield END_KW
    end

=begin rdoc
Generates the source lines for the given model,
yields the lines to the caller's block, use as:

    genSource{|line| ... }
=end
    def genSource
        yield '# model definition exported into the source code by DataMeta DOM'
        namespace = ''
        (@enums.keys + @records.keys).sort { |a, b| a.to_s <=> b.to_s }.each { |k|
            ns, base = DataMetaDom.splitNameSpace(k.to_s)
            if DataMetaDom.validNs?(ns, base) && ns != namespace
                namespace = ns
                yield "#{NAMESPACE} #{namespace}"
            end

            raise 'No version on the model' unless @ver
            raise "Version on the model is wrong type: #{@ver.inspect}" unless @ver.kind_of?(Ver)
            yield "#{VER_KW} #{@ver.full}"
            case
                when @records[k]
                    genSourceRec(@records[k], namespace, base) { |line| yield line }
                when @enums[k]
                    genSourceEnum(@enums[k], base) { |line| yield line }
                else
                    raise "Unsupported entity: #{e.inspect}"
            end
        }
    end
end

end
