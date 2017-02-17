$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'dataMetaDom'
require 'dataMetaDom/ver'
require 'treetop'
require 'dataMetaParse'
require 'bigdecimal'
require 'set'
require 'logger'
require 'erb'
require 'fileutils'
require 'pathname'

=begin rdoc
PII support for DataMeta

For command line details either check the new method's source or the README file, the usage section.

""
=end
module DataMetaPii
# Logger to use for this module
    L = Logger.new("#{File.basename(__FILE__)[0..-4]}.log", 0, 10_000_000)

    L.datetime_format = '%Y-%m-%d %H:%M:%S'

# Determine the gem root in the local Filesystem
    GEM_ROOT = Pathname.new(File.join(File.dirname(__FILE__), '..')).cleanpath
# Advance further to determine the root of the grammars
    GRAMMAR_ROOT = File.join(GEM_ROOT, 'grammar')

    # Current version
    VERSION = '1.0.1'
# Load base rules from the DataMeta Parsing Commons
    BASE_RULES = DataMetaParse.loadBaseRulz
# Load PII specific common rules from this very gem's codebase
    PII_COMMONS = Treetop.load(File.join(GRAMMAR_ROOT, 'piiCommons'))
# Load the PII Registry grammar
    REGISTRY = Treetop.load(File.join(GRAMMAR_ROOT, 'registry'))
# Load the PII Applications Link grammar
    APP_LINK = Treetop.load(File.join(GRAMMAR_ROOT, 'appLink'))
    L.info %<
Loaded base rules: #{DataMetaPii::BASE_RULES}
Loaded PII Commons Rules: #{DataMetaPii::PII_COMMONS.inspect}
Loaded Regstry Rules: #{DataMetaPii::REGISTRY}
Loaded AppLink Rules: #{DataMetaPii::APP_LINK}
>

# Create all parsers, it's not expensive. First the Registry (Abstract Defs) grammar parser:
    REGISTRY_PARSER = PiiRegistryParser.new
# And the App Link grammar parser:
    APP_LINK_PARSER = PiiAppLinkParser.new

# Value Object Class Key
    VO_CLASS_KEY = :voClass
# Value Reference Key
    REF_KEY = :ref
# Constant value key
    CONST_KEY = :const
# One step for indentation of the output
    INDENT = ' ' * 4
# Constant Data type: string
    STR_CONST_DT = :str
# Constant Data type:
    INT_CONST_DT = :int
# Constant Data type:
    DECIMAL_CONST_DT = :dec

# AST Node type
    ATTRB_LIST_NODE_TYPE = :attrbList
# AST Node type
    ATTRB_DEF_NODE_TYPE = :attrbDef

# Module-holder of the impact constants
# In a language that support enums, that'd be an enum.
    module Impact
# Impact Level: Public
        PUBLIC = :public
# Impact Level: Confidential
        CONFIDENTIAL = :confidential
# Impact Level: Internal
        INTERNAL = :internal
# Impact Level: Restricted
        RESTRICTED = :restricted
# Impact Level: Taboo
        TABOO = :taboo
    end

# Supported export (generation) formats
    module ExportFmts
# Code generation format: Java
        JAVA = :java
# Code generation format: Scala
        SCALA = :scala
# Code generation format: Python
        PYTHON = :python
# Code generation format: JSON
        JSON = :json
    end

# Collect all the constants from the module ExportFmts, that's all supported formats
    ALL_FMTS = ExportFmts.constants.map{|c| ExportFmts.const_get(c)}

# All supported impacts collected from the module Impact
    ALL_IMPACTS = Impact.constants.map{|c| Impact.const_get(c)}

# PII field definition scope: master vs application
    module Scope
# Abstract fields scope
        ABSTRACT = :abstract
# Application scope
        APPLICATION = :app
    end

# All supported scopes collected from the module Scope
    ALL_SCOPES = Scope.constants.map{|c| Scope.const_get(c)}

=begin rdoc
PII Registry Key Value Object, encapsulates the PII Registry Key with attributes
@!attribute [r] key
    @return [String] unique key for the given enum

@!attribute [r] level
    @return [Symbol] the impact level

=end
    class RegKeyVo
# The map key for the level
        LEVEL = 'level'

        attr_accessor :key, :level, :attrs
=begin rdoc
Creates an instance for the given parameters, see the properties with the same names.
=end
        def initialize(key, attrs)
            @key, @attrs = key, attrs
            # single the level out:
            levelSpec = attrs[LEVEL]

            raise ArgumentError, %<Impact level missing or empty in #{@attrs.inspect}> unless levelSpec && !levelSpec.empty?

            @level = levelSpec.to_sym

            raise ArgumentError, %<Unsupported Impact Level #{@attrs.inspect}. Supported levels are: #{
                ALL_IMPACTS.map(&:to_s).join(', ')}> unless ALL_IMPACTS.member?(@level)

            raise ArgumentError, %<Invalid PII key: "#{@key}"> unless @key =~ /^\w+$/
        end

# textual representation of this instance
        def to_s; "#{key}(#{@level})" end

# Builds a textual tree image for logging and/or console output
        def to_tree_image(indent = '')
            next_ident = indent + DataMetaPii::INDENT
            %<#{indent}#{@key}:
#{next_ident}#{@attrs.keys.map{|k| "#{k}=#{@attrs[k]}"}.join("\n#{next_ident}")}>
        end
    end

# Versioned Value Object common ancestor class
    class VersionedVo
        attr_accessor :ver
        def initialize(verDef)
            @ver = case verDef.class
                       when String.class
                           DataMetaDom::SemVer.new(verDef)
                       when DataMetaDom::SemVer.class
                           verDef
                       else
                           raise ArgumentError, %<Unsupported verDefsion type: #{verDef.class} == #{verDef.inspect}>
                   end

        end
    end

# Registry Value Object - a wrap around the PII Key to attributes map
    class RegVo < VersionedVo
        attr_accessor :keyVos
        def initialize(ver, vos)
            super(ver)
            @keyVos = vos
        end

# Builds a textual tree image for logging and/or console output
        def to_tree_image(indent = '')
            next_ident = indent + DataMetaPii::INDENT
            %<#{@keyVos.keys.map{|k| @keyVos[k].to_tree_image(next_ident)}.join("\n")}>
        end
    end

# Attribute definition ancestor - should be abstract but Ruby does not let define abstract classes easily.
    class AlAttrDef
        attr_accessor :key, :val
        def initialize(key, val)
            @key, @val = key, val
        end
    end

# Defines a value for a VO Class
    class AlAttrVoClass < AlAttrDef
        def initialize(voClass)
            super(VO_CLASS_KEY, voClass)
            raise ArgumentError, %<Wrong type for VO Class: #{voClass.class}=#{voClass.inspect}> unless voClass.is_a?(String)
        end
        # String representation
        def to_s; %<#{self.class.name}{#{val}}> end
    end
# Attribute reference
    class AttrRef
        attr_accessor :key
        def initialize(key); @key = key end
        # String representation
        def to_s; %<#{self.class.name}{#{@key}}> end
    end

# Attribute section with constants, references and a VO class optionally defined
    class AttrSect
        attr_reader :key, :refs, :consts, :voClass
        def initialize(key)
            @key = key
            @refs = Hash.new(*[])
            @consts = Hash.new(*[])
            @voClass = nil
        end

# Add a new value to this section, depending on the incoming type
        def +(val)
            case val
                when AlAttrVoClass
                    raise RuntimeError, %<Attempt to redefine VO Class on "#{@key}"> if @voClass
                    @voClass = val

                when AttrRef
                    raise RuntimeError,
                          %<Reference to "#{val.key}" specified more than once on the attribute section "#{
                            @key}"> if @refs.has_key?(val.key.to_sym)

                    @refs[val.key.to_sym] = val

                when AlAttrStr, AlAttrInt, AlAttrDec
                    raise RuntimeError,
                          %<Constant "#{val.key}" specified more than once on "#{@key}"> if @consts.has_key?(val.key.to_sym)

                    @consts[val.key.to_sym] = val
                else
                    raise ArgumentError, %<Unsupported attribute type #{val.class} = #{val.inspect}>
            end
        end

        # String representation
        def to_s
            %<#{self.class.name}{VO=#{@voClass}, Refs=#{@refs.inspect}, Const=#{@consts.inspect}}>
        end
    end

# Defines a value for a String constant
    class AlAttrStr < AlAttrDef
        def initialize(key, val)
            super(key, val)
            raise ArgumentError, %<Wrong type for a String: #{val.class}=#{val.inspect}> unless val.is_a?(String)
        end
        # String representation
        def to_s; %<#{self.class.name}{#{key}=#{val.inspect}}> end
    end

# Defines a value for an Int constant
    class AlAttrInt < AlAttrDef
        def initialize(key, val)
            super(key, val)
            raise ArgumentError, %<Wrong type for an Int: #{val.class}=#{val.inspect}> unless val.is_a?(Fixnum)
        end
        # String representation
        def to_s; %<#{self.class.name}{#{key}=#{val}}> end
    end

# Defines a value for an Decimal constant
    class AlAttrDec < AlAttrDef
        def initialize(key, val)
            super(key, val)
            raise ArgumentError, %<Wrong type for an Decimal: #{val.class}=#{val.inspect}> unless val.is_a?(BigDecimal)
        end
        # String representation
        def to_s; %<#{self.class.name}{#{key}=#{val.to_s('F')}}> end
    end

# AppLink Attribute VO
    class AlAttrVo # - FIXME - not needed?
        attr_accessor :key, :attrs
=begin rdoc
Creates an instance for the given parameters, see the properties with the same names.
=end
        def initialize(key, attrs)
            @key, @attrs = key, attrs
        end
    end

# Application Link VO - FIXME - not needed?
    class PiiAlVo
        attr_accessor :key, :attrs
=begin rdoc
Creates an instance for the given parameters, see the properties with the same names.
=end
        def initialize(key, attrs)
            @key, @attrs = key, attrs
        end

    end

=begin
AppLink Attribute Division VO, i.e. full Application Link Definition

@!attribute [rw] sectVos
    @return [Hash] the Hash keyed by the application name symbol pointing to a Hash keyed by the Abstract
        PII field key pointing to the instance of AttrSect.

@!attribute [rw] reusables
    @return [Hash] +nil+ or the Hash keyed by reusable var name pointing to the instance of AttrSect
        PII field key pointing to the instance of AttrSect.
=end
    class AppLink < VersionedVo

        # Use same ident as the main class:
        INDENT = DataMetaPii::INDENT
        
        attr_accessor :sectVos, :reusables
=begin rdoc
Creates an instance for the given parameters, see the properties with the same names.
=end
        def initialize(ver, vos, reusables = nil)
            super(ver)
            @sectVos, @reusables = vos, reusables
        end

        # Resolves reusable variable references, reports errors
        def resolveRefs()
            raise ArgumentError, 'Sections are not set yet on this instance' unless @sectVos
            return self unless @reusables # no reusables defined, all vars should be accounted for
            @reusables.keys.each { |uk|
               ref = @reusables[uk].refs
               ref.keys.each { |rk|
                  raise ArgumentError, %<Reusable "#{uk}" references "#{rk}" which is not defined> unless @reusables[rk]
               }
            }
            @sectVos.keys.each { |ak|
                app = @sectVos[ak]
                app.keys.each { |sk|
                    sect = app[sk]
                    sect.refs.keys.each { |rk|
                        raise ArgumentError, %<In the app "#{ak}": the field "#{sk}" references "#{
                                rk}" which is not defined> unless @reusables[rk]
                    }
                }

            }
            self
        end

        # String representation
        def to_s
            %<#{self.class.name}{apps=#{@sectVos.inspect}>
        end
    end

# Builds the AppLink CST from the given Registry Grammar Parser's AST
    def buildAlCst(ast, logString = nil)
        # parse the ad first
        reusables = {}
        log = -> (what) {logString << what if logString}

        log.call("AppLink CST\n")
        if ast.ad&.elements
            log.call("#{INDENT}#{ast.ad.type}:#{ast.ad.a.elements.size}\n")
            ast.ad.a.elements.each { |as| # attrbSection
                raise RuntimeError, %<The attributes set "#{as.pk} is defined more than once"> if reusables.has_key?(as.pk.to_sym)
                keyVals = digAstElsType(ATTRB_DEF_NODE_TYPE, as.a.elements)
                log.call(%<#{INDENT * 2}#{as.pk}:#{keyVals.size}\n>)
                aSect = AttrSect.new(as.pk.to_sym)
                keyVals.each { |kv|
                    kvVal = kv.val
                    log.call(%<#{INDENT * 3}#{kv.nodeType}:#{kvVal}\\#{kvVal.class}>)
                    log.call(" (#{kv.node.key}==#{kv.node.nodeVal})//#{kv.node.type}\\#{kv.node.dataType}") if(kv.nodeType == CONST_KEY)
                    log.call("\n")
                    # noinspection RubyCaseWithoutElseBlockInspection
                     aSect + case kv.nodeType # else case is caught by the AST parser
                                  when CONST_KEY
                                      # noinspection RubyCaseWithoutElseBlockInspection
                                      klass = case kv.node.dataType # else case is caught by the AST parser
                                                  when STR_CONST_DT
                                                      AlAttrStr
                                                  when DECIMAL_CONST_DT
                                                      AlAttrDec
                                                  when INT_CONST_DT
                                                      AlAttrInt
                                              end
                                      klass.new(kv.node.key.to_sym, kv.node.nodeVal)
                                  when REF_KEY
                                      AttrRef.new(kvVal)
                                  when VO_CLASS_KEY
                                      AlAttrVoClass.new(kvVal)
                              end
                }
                reusables[as.pk.to_sym] = aSect
            }
            log.call(%<#{INDENT * 2}#{reusables}\n>)
        else
            log.call("#{INDENT * 2}No reusables\n")
        end
        apps = {}
        if ast.al&.elements
            log.call("#{INDENT}#{ast.al.type}:#{ast.al.a.elements.size}\n")
            ast.al.a.elements.each { |as| # appLinkApps
                log.call(%<#{INDENT * 3}#{as.ak}:#{as.a.elements.size}\n>)
                appKey = as.ak.to_sym
                raise RuntimeError, %<Application "#{appKey}" defined more than once> if apps.has_key?(appKey)
                attrbs = {}
                as.a.elements.each { |ala| #appLinkAttrbs
                    alis = digAstElsType(DataMetaPii::ATTRB_DEF_NODE_TYPE, ala.a.elements)
                    log.call(%<#{INDENT * 4}#{ala.pk} (#{ala.type}): #{alis.size}\n>)
                    aSect = AttrSect.new(ala.pk.to_sym)
                    alis.each { |ali|
                       kvVal = ali.val
                       log.call(%<#{INDENT * 5}#{ali.nodeType}: >)
                        if ali.nodeType == DataMetaPii::CONST_KEY
                            log.call(%<(#{ali.node.dataType}):: #{ali.node.key}=#{ali.node.nodeVal}>)
                        else
                           log.call(%<#{ali.val}>)
                        end
                       # noinspection RubyCaseWithoutElseBlockInspection
                       aSect + case ali.nodeType # else case is caught by the AST parser
                                   when CONST_KEY
                                       # noinspection RubyCaseWithoutElseBlockInspection
                                       klass = case ali.node.dataType # else case is caught by the AST parser
                                                   when STR_CONST_DT
                                                       AlAttrStr
                                                   when DECIMAL_CONST_DT
                                                       AlAttrDec
                                                   when INT_CONST_DT
                                                       AlAttrInt
                                               end
                                       klass.new(ali.node.key.to_sym, ali.node.nodeVal)
                                   when REF_KEY
                                       AttrRef.new(kvVal)
                                   when VO_CLASS_KEY
                                       AlAttrVoClass.new(kvVal)
                               end
                        log.call("\n")
                    }
                    attrbs[ala.pk.to_sym] = aSect
                }
                log.call(%<#{INDENT}#{attrbs}\n>)
                apps[appKey] = attrbs
            }
        else
            raise ArgumentError, 'No Applink Division'
        end
        AppLink.new(ast.verDef.ver, apps, reusables)
    end

# Builds the Registry CST from the given Registry Grammar Parser's AST
    def buildRegCst(ast)

        resultMap = {}

        ast.fields.elements.each { |f|
            fKey = f.pk
            raise ArgumentError, %<The PII field #{fKey} is defined more than once> if resultMap.keys.member?(fKey)
            attrs = {}
            f.attrbLst.attrbs.each { |a|
                raise ArgumentError, %<Attribute "#{a.k}" is defined more than once for #{fKey}> if attrs.keys.member?(a.k)
                attrs[a.k] = a.v
            }
            attrVo = RegKeyVo.new(fKey, attrs)
            resultMap[fKey] = attrVo
        }

        RegVo.new(ast.verDef.ver, resultMap)
    end

# Helper method for the AST traversal to collect the attributes
# Because of the Treetop AST design, can not just flatten the elements and select of those of the needed type in one call, hence the tree traversal
    def digAstElsType(type, els, result=[])
        if els.nil? # is it a leaf?
            nil # not a leaf - return nil
        else
            els.each { |e|
                if e.respond_to?(:type) && e.type == type # actual attribute Key/Value?
                    result << e # add it
                else
                    digAstElsType(type, e.elements, result) # dig deeper into the AST
                end
            }
            result
        end
    end

    def errNamespace(outFmt)
        raise ArgumentError, %<For output format "#{outFmt}", the Namespace is required>
    end

# API method: generate the PII code
    def genCode(scope, outFmt, outDirName, source, namespace = nil)
# noinspection RubyCaseWithoutElseBlockInspection
        codeIndent = ' ' * 2 
        raise ArgumentError, %Q<Unsupported scope definition "#{scope}", supported scopes are: #{
            DataMetaPii::ALL_SCOPES.map(&:to_s).join(', ')}> unless ALL_SCOPES.member?(scope)

        raise ArgumentError, %Q<Unsupported output format definition "#{outFmt}", supported formats are: #{
            DataMetaPii::ALL_FMTS.map(&:to_s).join(', ')}> unless ALL_FMTS.member?(outFmt)

        raise ArgumentError, %<For safety purposes, absolute path names like "#{
            outDirName}" are not supported> if outDirName.start_with?('/')

        raise ArgumentError, %<The output dir "#{outDirName}" is not a directory> unless File.directory?(outDirName)

        # noinspection RubyCaseWithoutElseBlockInspection
        case scope # else case caught up there, on argument validation
            when Scope::ABSTRACT
                reg = DataMetaPii.buildRegCst(DataMetaParse.parse(REGISTRY_PARSER, source))
                L.info(%<PII Registry:
#{reg.to_tree_image(INDENT)}>)
                tmpl = ERB.new(IO.read(File.join(GEM_ROOT, 'tpl', outFmt.to_s, 'master.erb')), $SAFE, '%<>>')
                className = "PiiAbstractDef_#{reg.ver.toVarName}"
                # noinspection RubyCaseWithoutElseBlockInspection
                case outFmt
                    when ExportFmts::JAVA, ExportFmts::SCALA
                        errNamespace(outFmt) unless namespace.is_a?(String) && !namespace.empty?
                        pkgDir = namespace.gsub('.', '/')
                        classDest =File.join(outDirName, pkgDir)
                        FileUtils.mkpath classDest

                        IO.write(File.join(classDest, "#{className}.#{outFmt}"),
                                 tmpl.result(binding).gsub(/\n\n+/, "\n\n"), mode: 'wb') # collapse multiple lines in 2

                    when ExportFmts::JSON
                        IO.write(File.join(outDirName, "#{className}.#{outFmt}"),
                                 tmpl.result(binding).gsub(/\n\n+/, "\n\n"), mode: 'wb') # collapse multiple lines in 2

                    when ExportFmts::PYTHON
                        pkgDir = namespace.gsub('.', '_')
                        classDest =File.join(outDirName, pkgDir)
                        FileUtils.mkpath classDest
                        IO.write(File.join(classDest, "#{className[0].downcase + className[1..-1]}.py"),
                                 tmpl.result(binding).gsub(/\n\n+/, "\n\n"), mode: 'wb') # collapse multiple lines in 2
                        IO.write(File.join(classDest, '__init__.py'), %q<
# see https://docs.python.org/3/library/pkgutil.html
# without this, Python will have trouble finding packages that share some common tree off the root
from pkgutil import extend_path
__path__ = extend_path(__path__, __name__)

>, mode: 'wb')
                end

            when DataMetaPii::Scope::APPLICATION
                raise NotImplementedError, 'There is no generic code gen for AppLink, each app/svc should have their own'

        end
    end

=begin
Turns the given text into the instance of the AppLink object.
=end
    def parseAppLink(source)

        piiAppLinkParser = PiiAppLinkParser.new
        ast = DataMetaParse.parse(piiAppLinkParser, source)
        raise SyntaxError, 'AppLink parse unsuccessful' unless ast
        if ast.is_a?(DataMetaParse::Err)
            raise %<#{ast.parser.failure_line}
ast.parser.failure_reason}>
        end

        DataMetaPii.buildAlCst(ast).resolveRefs
    end

    module_function :digAstElsType, :buildRegCst, :buildAlCst, :genCode, :errNamespace, :parseAppLink
end
