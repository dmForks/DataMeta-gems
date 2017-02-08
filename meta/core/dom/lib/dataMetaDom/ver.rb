$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'fileutils'
require 'typesafe_enum'
require 'set'
require 'dataMetaDom/docs'

module DataMetaDom

=begin
Semantic Version implementation.

See {http://semver.org this page} for details
=end
    class SemVer
        attr_reader :source, :semanticPartsOnly, :items
# Version difference levels as an enum
        class DiffLevel < TypesafeEnum::Base
            new :NONE   # Versions are equal
            new :MAJOR  # Difference in the Major part
            new :MINOR  # Difference in the Minor part
            new :UPDATE # Difference in the Update (Patch) part
            new :BUILD  # Difference in the Build part
        end

       # Split by dots pattern
        DOTS_SPLIT = %r<\.>
       # Any Integral part of the Version - just digits
        DIGITS = %r<^[0-9]+$>

        # Major part index in the @items array
        MAJOR_INDEX = 0
        # Minor part index in the @items array
        MINOR_INDEX = MAJOR_INDEX + 1
        # Update part index in the @items array
        UPDATE_INDEX = MINOR_INDEX + 1
        # Build part index in the @items array
        BUILD_INDEX = UPDATE_INDEX + 1
        # Minimal size of the @items array
        ITEMS_MIN_SIZE = UPDATE_INDEX + 1
        # Max size of the @items array
        ITEMS_MAX_SIZE = BUILD_INDEX + 1

        # Equality for the saucer operator <=>
        EQ = 0
        # Strictly "greater than" for the saucer operator <=>
        GT = 1
        # Strictly "lesser than" for the saucer operator <=>
        LT = -1

# Parsing constructor
        def initialize(src)
            raise ArgumentError, "Attempted to create an instance of #{self.class.name} from a nil" if src.nil?
            @source = src
            # put everything in an array -- this provides free eql? and hash() methods
            @items = []
            src.split(DOTS_SPLIT).each { |i|
                if i =~ DIGITS
                    @items << i.to_i
                else
                    break
                end
            }
            raise ArgumentError, %<Invalid semantic version format: #{src}> if items.size < ITEMS_MIN_SIZE ||
                    items.size > ITEMS_MAX_SIZE

            raise ArgumentError,
                  %<Invalid semantic version format: "#{src}": build version can not be zero.> unless build.nil? ||
                    build != 0

            @semanticPartsOnly  = @items.map{|i| i.to_s}.join('.')

        end

        # Major part of the version
        def major; @items[MAJOR_INDEX] end

        # Minor part of the version
        def minor; @items[MINOR_INDEX] end

        # Update part of the version
        def update; @items[UPDATE_INDEX] end

        # Build part of the version or nil
        def build; items.size > BUILD_INDEX ? @items[BUILD_INDEX] : nil end

# Difference Level, computes one of the DiffLevel values
        def diffLevel(other)
            return DiffLevel::MAJOR if major != other.major
            return DiffLevel::MINOR if minor != other.minor
            return DiffLevel::UPDATE if update != other.update
            if (
               !build.nil? && !other.build.nil? && (build <=> other.build) != EQ
            ) || (
               build.nil? && !other.build.nil?
            ) || ( !build.nil? && other.build.nil? )
                return DiffLevel::BUILD
            end
            DiffLevel::NONE
        end

# Override the eql? for the == operator to work
        def eql?(o); @items == o.items end

# Override the hash() method for the sets and maps to work
        def hash; @items.hash end

# The Saucer Operator, Ruby equivalent of Java's compareTo(...)
        def <=>(o)
            raise ArgumentError, %<Attempt to compare #{self.class.name} "#{self}" to a nil> if o.nil?

            0.upto(UPDATE_INDEX) { |x|
                cmp = items[x] <=> o.items[x]
                return cmp unless cmp == EQ #  not equal: end of the story, that's the comparison result
            }
            # if we are here, the Minor, Major and the Update are equal. See what's up with the build if any:

            # this object is newer (version bigger) because it has a build number but the other does not
            return GT if items.size > o.items.size

            # this object is older (version lesser) because it does not have a build number but the other does
            return LT if items.size < o.items.size

            # We got build part in self and the other, return the build part comparison:
            build <=> o.build
        end

        # For a simple string representation, just show the source
        def to_s; @source end

        # Long string for debugging and detailed logging - shows semantic parts as parsed
        def to_long_s; "#{self.class.name}{#{@source}(#{@semanticPartsOnly})}" end

=begin
Consistently and reproducibly convert the version specs to the text suitable for making it a part of a class name or a
variable name
=end
        def toVarName; @items.join('_') end

# Overload the equals operator
        def ==(other); self.<=>(other) == EQ end
# Overload the greater-than operator
        def >(other); self.<=>(other) == GT end
# Overload the lesser-than operator
        def <(other); self.<=>(other) == LT end
# Overload the greater-than-or-equals operator
        def >=(other); self.<=>(other) >= EQ end
# Overload the lesser-than-or-equals operator
        def <=(other); self.<=>(other) <= EQ end

        class << self
# Builds an instance of SemVer from the given specs whatever they are
            def fromSpecs(specs)
                case specs
                    when SemVer
                        specs
                    when String
                        SemVer.new(specs)
                    else
                        raise ArgumentError, %<Unsupported SemVer specs type #{specs}==#{specs.inspect}>
                end
            end
        end
    end

=begin rdoc
Version info.
=end
    class Ver
=begin rdoc
Full version info.
=end
        attr_accessor :full

=begin rdoc
Creates an instance with the given full version.
=end
        def initialize(specs)
            @full = if specs.kind_of?(Integer)
                        raise ArgumentError,
                              %|Invalid version specs: "#{specs
                              }"; a version must be of a valid Semantic format|
                    else
                       SemVer.fromSpecs(specs)
                    end
        end

        class << self
# Reversions all the files in the given paths recursively
            def reVersion(path, namespace, globs, srcVer, trgVer)
                vPat = srcVer ? srcVer.toVarName : '\d+_\d+_\d+'
                globs.each { |g|
                    Dir.glob("#{path}/#{g}").each { |f|
                        origLines = IO.read(f).split("\n")
                        newLines = []
                        origLines.each { |line|
                            newLines << (line.end_with?('KEEP') ? line :
                                    line.gsub(%r~#{namespace.gsub(/\./, '\.')}\.v#{vPat}~, "#{namespace}.v#{trgVer.toVarName}"))
                        }
                        IO.write(f, newLines.join("\n"), mode: 'wb')
                    }
                }
                Dir.entries(path).select{|e| File.directory?(File.join(path, e))}.reject{|e| e.start_with?('.')}.each {|d|
                    reVersion File.join(path, d), namespace, globs, srcVer, trgVer
                }

            end

        end

=begin rdoc
Textual presentation for the instance.
=end
        def to_s; "ver #{full}" end
    end

=begin rdoc
Anything having a version. It must be also documentable, but not everything documentable is also versionable,
like, for example, Record Field or an Enum part.
=end
    class VerDoccable < Documentable
=begin rdoc
The version info, an instance of Ver.
=end
        attr_accessor :ver
=begin rdoc
Resets stateful information on the entity level, like docs that should not apply to the next entity if missing.
=end
        def resetEntity
            docs.clear
        end


=begin rdoc
Attempts to parse an instance of Ver from the current line on the given instance of SourceFile.
Returns the instance of Ver if successful, nil otherwise.
Parameter:
* +src+ - the instance of SourceFile to parse the version info from.
=end
        def self.verConsumed?(src)
            src.line =~ /^\s*#{VER_KW}\s+(\S+)\s*$/ ? Ver.new($1) : nil
        end

    end
end
