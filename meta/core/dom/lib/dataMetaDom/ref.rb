$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set).each { |r| require r }

module DataMetaDom

=begin rdoc
A reference to another entity on this Model, any of:
* Record
* Enum
* BitSet
* Map

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Reference

=begin rdoc
Type of a reference - unresolved.
=end
    UNRESOLVED = :u

=begin rdoc
Type of a reference - to a Record.
=end
    RECORD = :r

=begin rdoc
Type of a reference - to an Enum, a BitSet or a Map.
=end
    ENUM_REF = :e

=begin rdoc
The unique key for the reference to use in a hashmap.
=end
    attr_accessor :key

=begin rdoc
The field the reference originates from, an instance of a Field
=end
    attr_accessor :fromField

=begin rdoc
The Record the reference originates from, an instance of a Record
=end
    attr_accessor :fromEntity

=begin rdoc
The target Field of the reference, must be the only one field in the target Record's identity,
determined by the resolve method.
=end
    attr_accessor :toFields

=begin rdoc
The target entity for this Reference, determined by the resolve method. If it is a Record,
the record must have an identity consisting from only one field.
=end
    attr_accessor :toEntity

=begin rdoc
Reference to the source where this reference has been defined, if any.
=end
    attr_accessor :sourceRef

=begin rdoc
The type of the reference, UNRESOLVED or RECORD or ENUM_REF.
=end
    attr_accessor :type

=begin rdoc
Creates an instance with the given parameters.
* Parameters:
  * +sourceEntity+ - the instance of Record the reference originates from.
  * +sourceField+ - the instance of Field the reference originates from
  * +targetEntitySpec+ - a string, specification of the target entity to be resolved
  * +sourceRef+ - an instance of SourceFile
=end
    def initialize(sourceEntity, sourceField, targetEntitySpec, sourceRef = nil)
        @sourceRef = sourceRef
        @targetEntitySpec = targetEntitySpec.to_sym; @fromEntity = sourceEntity; @fromField = sourceField
        @type = UNRESOLVED
        self
    end

=begin rdoc
Resolve the target entity and the field on the given Model.
=end
    def resolve(model)
        #@fromField = @fromEntity[@sourceFieldSpec.to_sym]
        #raise "The field #@sourceFieldSpec is not defined on this entity: #@fromEntity, #@sourceRef" unless @fromField
        @toEntity = model.records[@targetEntitySpec] || model.enums[@targetEntitySpec]
        raise "Target entity #{@targetEntitySpec} is not defined; #{@sourceRef}" unless @toEntity
        case # IMPORTANT!! make sure that you do not inspect and do not use Entity.to_s - this will blow up the stack
            when @toEntity.kind_of?(Enum), @toEntity.kind_of?(BitSet), @toEntity.kind_of?(Mappings)
                @type = ENUM_REF
                @key= "#{@type}/#{@fromEntity.name}.#{@fromField.name}->#{@toEntity.name}"
            when @toEntity.kind_of?(Record)
                idy = @toEntity.identity
#                raise "#@targetEntitySpec does not have an identity, can not be referenced to in IDL; #@sourceRef" unless idy
#
#                raise "Invalid ref #{@fromEntity.name}.#{@toField.name} -> #@toEntity"\
#             "- it has no singular ID; #@sourceRef" unless idy.args.length == 1

                @type = RECORD
                @toFields = idy ? idy.args : @toEntity.fields.keys
#                raise "The field #{idy.args[0]} is not defined on this entity: #@toEntity; #@sourceRef" unless @toField
                @key = "#{@type}/#{@fromEntity.name}.#{@fromField.name}->#{@toEntity.name}.#{@toFields.join(',')}"
            else
                raise "Unsupported target entity: #{@toEntity.name}, for #{@sourceRef}"
        end
    end

=begin rdoc
Textual representation of this Reference. Need to be careful because the to_s on the Record includes a list of references
and if you include a Record in this textual, this will cause infinite recursion with the stack failure.
=end
    def to_s
        case @type
            when UNRESOLVED; "Unresolved: #{@fromEntity.name}.#{@fromField.name} ==> #@targetEntitySpec; #@sourceRef"
            when RECORD; "Record Ref: #@key"
            when ENUM_REF; "Enum ref: #@key"
            else; raise "Unsupported reference type #@type; #@sourceRef"
        end
    end
end

end
