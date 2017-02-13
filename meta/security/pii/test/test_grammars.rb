require './test/test_helper.rb'

=begin rdoc
Test for the DataMetaPii grammars and parsing.

Assertions: http://ruby-doc.org/stdlib-1.9.3/libdoc/test/unit/rdoc/Test/Unit/Assertions.html
=end
class TestPiiFmts < Test::Unit::TestCase

    include DataMetaPiiTests

    # loads the fmt grammar and creates the parser instance
    def setup

        @registryParser = PiiRegistryParser.new
        @piiAppLinkParser = PiiAppLinkParser.new
        L.info %<DataMeta PII Registry parser: #{@registryParser.inspect}
DataMeta PII App Link parser: #{@piiAppLinkParser.inspect}
>
    end

=begin rdoc
Test Pii Registry DML parsing
=end
    def test_registry_parse
        ast = DataMetaParse.parse(@registryParser, IO.read('./test/registryShowcase.dmPii'))
        L.info 'Registry parse start'
        raise 'Registry File Format parse unsuccessful' unless ast
        raise ast if ast.is_a?(DataMetaParse::Err)
        #L.info "AST:\n#{ast.fields.inspect}"
        #L.info "----------AST:\n#{ast.inspect}"
        #elems = [ast.items.elements]
        #elems = [ast.fields]
        #L.info "===========AST Fields:\n#{elems.inspect}\n==================="
        ast.fields.elements.each { |f|
            L.info("PII Key: #{f.pk}: #{f.attrbLst.attrbs.map{|e| "#{e.k}::#{e.v}"}.join('; ')}")
        }
        L.info(%<PII Registry:
#{DataMetaPii.buildRegCst(ast).to_tree_image(DataMetaPii::INDENT)}>)
    end

=begin rdoc
Test Pii Registry DML parsing and structuring - full version
=end
    def test_app_link_parse_full
        L.info 'Full applink parse start'
        ast = DataMetaParse.parse(@piiAppLinkParser, IO.read('./test/appLinkFull.dmPii'))
        raise 'Full AppLink parse unsuccessful' unless ast
        if ast.is_a?(DataMetaParse::Err)
            raise %<#{ast.parser.failure_line}
#{ast.parser.failure_reason}>
        end
        #L.info "AST:\n#{ast.fields.inspect}"
        #L.info "----------AST:\n#{ast.inspect}"
        #elems = [ast.items.elements]
        #elems = [ast.fields]
        #L.info "===========AST Fields:\n#{elems.inspect}\n==================="
        ast.elements[1].elements.each { |f|
            if f.respond_to?(:type) && f.type == 'refVal'
                L.info(%<refVal: #{f.sym}>)
            else
                L.info(%<AppLink Elem: #{f.inspect}>)
            end
        }
        ast.elements[3].elements.each { |f|
            if f.respond_to?(:type) && f.type == 'refVal'
                L.info(%<refVal: #{f.sym}>)
            else
                L.info(%<AppLink Elem: #{f.inspect}>)
            end
        }
        log = ''
        appLinkObj = DataMetaPii.buildAlCst(ast, log)

        L.info(%<AppLink Full:
#{appLinkObj}
Building log:
#{log}
>)#.to_tree_image(DataMetaPii::INDENT_STEP)}>)

    end

    def test_app_link_parse_method
        appLinkModel = DataMetaPii.parseAppLink(IO.read('./test/appLinkFull.dmPii'))
        L.info(%<AppLink Model - full:
#{appLinkModel.inspect}>)
    end

=begin rdoc
Test Pii Registry DML parsing - showcase version, do not run this tree through CST builder!
=end
    def test_app_link_parse_showcase
        L.info 'Showcase applink parse start'
        ast = DataMetaParse.parse(@piiAppLinkParser, IO.read('./test/appLinkShowcase.dmPii'))
        raise 'Showcase File Format parse unsuccessful' unless ast
        if ast.is_a?(DataMetaParse::Err)
            raise %<#{ast.parser.failure_line}
                  #{ast.parser.failure_reason}>
        end
        #L.info "AST:\n#{ast.fields.inspect}"
        #L.info "----------AST:\n#{ast.inspect}"
        #elems = [ast.items.elements]
        #elems = [ast.fields]
        #L.info "===========AST Fields:\n#{elems.inspect}\n==================="
        ast.elements[1].elements.each { |f|
            if f.respond_to?(:type) && f.type == 'refVal'
                L.info(%<refVal: #{f.sym}>)
            else
                L.info(%<AppLink Elem: #{f.inspect}>)
            end
        }
        ast.elements[3].elements.each { |f|
            if f.respond_to?(:type) && f.type == 'refVal'
                L.info(%<refVal: #{f.sym}>)
            else
                L.info(%<AppLink Elem: #{f.inspect}>)
            end
        }
    end

=begin rdoc
Test Pii Registry DML parsing - version with no reusables, must be successfully processed by the CST builder
=end
    def test_app_link_parse_no_reusables
        L.info 'No-reusables applink parse start'
        ast = DataMetaParse.parse(@piiAppLinkParser, IO.read('./test/appLinkNoReusables.dmPii'))
        raise 'No-reusables File Format parse unsuccessful' unless ast
        if ast.is_a?(DataMetaParse::Err)
            raise %<#{ast.parser.failure_line}
                  #{ast.parser.failure_reason}>
        end
        #L.info "AST:\n#{ast.fields.inspect}"
        #L.info "----------AST:\n#{ast.inspect}"
        #elems = [ast.items.elements]
        #elems = [ast.fields]
        #L.info "===========AST Fields:\n#{elems.inspect}\n==================="
        ast.elements[0].elements.each { |f|
            if f.respond_to?(:type) && f.type == 'refVal'
                L.info(%<refVal: #{f.sym}>)
            else
                L.info(%<AppLink Elem: #{f.inspect}>)
            end
        }
        log = ''
        applinkObj = DataMetaPii.buildAlCst(ast, log)
        L.info(%<AppLink No Reusables:
#{applinkObj.inspect}
Building log:
#{log}
>)#.to_tree_image(DataMetaPii::INDENT_STEP)}>)
    end
end
