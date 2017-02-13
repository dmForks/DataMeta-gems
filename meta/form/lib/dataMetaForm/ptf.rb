$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'dataMetaDom/dataType'
require 'dataMetaParse'

module DataMetaForm

=begin rdoc
Datetime module.
=end
    module Dttm
=begin rdoc
Map from DataMetaForm datetime format tokens to those for Ruby APIs.

Decision was made to use Java formats for DataMetaForm because they are more intuitive and will be much more frequently
used.

Incoming tokens not present in this map will be preserved verbatim as delimiters and such.

Example of using the result with Joda:
    org.joda.time.format.DateTimeFormat.forPattern("yyyy-MM-dd HH:mm:ss").parseDateTime("2013-01-022:03:04")
=end
        FMT_TOKS = { 'yyyy' => '%Y', 'MM' => '%m', 'dd' => '%d', 'HH' => '%H', 'mm' => '%M', 'ss' => '%S' }
=begin rdoc
Helper regex to use for transforming DataMetaForm datetime format to the Ruby format.

This simple and effective way of building this regex will break if a new key appears in the {FMT_TOKS}
hash that is a part of another. For example, if you add 'yy' pointing to '%y', then would have to put this
map together manually, having 'yyyy' appear first in the regex, before 'yy' and making sure there will be
no other year token in any of the parsed formats. Test everything.
=end
        TOK_MATCH = /#{FMT_TOKS.keys.join('|') + '|.'}/

=begin rdoc
Transform DataMetaForm date format to Ruby API formats

* {Java}[http://joda-time.sourceforge.net/apidocs/org/joda/time/format/DateTimeFormat.html]: +yyyy-MM-dd HH:mm:ss+
* {DataMetaForm/Ruby}[http://www.ruby-doc.org/stdlib-1.9.3/libdoc/date/rdoc/DateTime.html#method-i-strftime]: +%Y-%m-%d %H:%M:%S+

@param [String] fmt DataMetaForm/Java datetime format to convert to Ruby format

@return [String] the datetime format to use with the target platform as shown in the examples per the references above.
=end
        def toRubyFmt(fmt); toDttmFmt(fmt, FMT_TOKS, TOK_MATCH) end

=begin rdoc
Transforms one datetime format into another by the given token map and given split regex.

See {FMT_TOKS} and {TOK_MATCH} for examples and details about the parameters +tokenMap+ and +tokenSplit+.

@param [String] fmt DataMetaForm/Java datetime format to convert to Ruby format
@param [Hash] tokenMap a map from source datetime format tokens into target tokens
@param [Regexp] tokenSplit the regular expression to split the tokens by to get an array of tokens and non-tokens
    in the order they appear
@raise [ArgumentError] in case of argument type mismatch
@return [String] the target format string, +nil+ if fmt is nil
=end
        def toDttmFmt(fmt, tokenMap, tokenSplit)
            return nil unless fmt
            raise ArgumentError, "Argument type mismatch: fmt(#{fmt.class}), tokenMap(#{tokenMap.class}), " +
                    "tokenSplit(#{tokenSplit.class}" unless fmt.kind_of?(String) &&
                    tokenMap.kind_of?(Hash) && tokenSplit.kind_of?(Regexp)
            result = ''
            (fmt.scan(tokenSplit) || []).each { |x| result << (tokenMap[x] || x) }
            result
        end

        module_function :toDttmFmt, :toRubyFmt
    end

=begin rdoc
Specifically Format related: domain objects definitions, model tokens etc.
=end
    module Fmt

=begin rdoc
Ancestor for all field items, for identification of such and common functionality if one comes up.
A Marker Class for now.
=end
        class FmtItem
        end
=begin rdoc
Format model token - delimiter
@!attribute [r] val
    @return [String] delimiter's string value

=end
        class Delim < FmtItem
            attr_reader :val

=begin rdoc
UTF (or ASCII for numbers <138) code mapping to the symbol which is a mnemonic to represent this value in the
source code.

See the full {ASCII table with mnemonics we use here}[http://www.asciitable.com]
or {here}[http://www.december.com/html/spec/ascii.html].

Use the +.ord+ method to get a character's numeric value to use as a key in this table, use the +.chr+ method
to turn the int to the character.
=end
            TO_MNEM = {
                0 => :NUL,  1 => :SOH,  2 => :STX,  3 => :ETX,  4 => :EOT,  5 => :ENQ,  6 => :ACK,  7 => :BEL,
                8 => :BS,   9 => :HT,  10 => :NL,  11 => :VT,  12 => :NP,  13 => :CR,  14 => :SO,  15 => :SI,
               16 => :DLE, 17 => :DC1, 18 => :DC2, 19 => :DC3, 20 => :DC4, 21 => :NAK, 22 => :SYN, 23 => :ETB,
               24 => :CAN, 25 => :EM,  26 => :SUB, 27 => :ESC, 28 => :FS,  29 => :GS,  30 => :RS,  31 => :US,
               32 => :SP
 # decimal 13 (CR)is also known as "\r", and decimal 10 (NL, LF) as "\n"
            }
=begin rdoc
The inversion of the {TO_MNEM} Hash, mapping the source code mnemonic to the int code, adding some extra mappings
add TAB for HT and LF (linefeed)for NL
=end
            TO_NUM = TO_MNEM.invert.merge({ 9 => :TAB, "\n".ord => :LF }.invert)

=begin rdoc
Creates an instance from DataMetaForm source for a delimiter.
@param [String] source the DataMetaForm source for the delimiter, past the backslash symbol
=end
            def self.fromDataMetaForm(source)
                code = TO_NUM[source.to_sym]
                raise ArgumentError, %Q<Delimiter symbol "#{source}" not supported> unless code
                Delim.new(code.chr)
            end

=begin rdoc
Constructor.
@param [String] val see the property {#val}
@raise [ArgumentError] if the argument is empty
=end
            def initialize(val)
                raise ArgumentError, 'Empty delimiters are not supported' if val.empty?
                @val = val
            end

=begin rdoc
Transforms the instance into DataMetaForm source code
@return [String] DataMetaForm source for the instance

@raise [RuntimeError] if the length of the {#val} is greater than  1; or if the code is not in {TO_MNEM}
=end
            def toDataMetaForm
                raise %Q<Multi-char delimiters such as "#{@val}" are not supported in DataMetaForm> if @val.length > 1
                result = TO_MNEM[@val.ord]
                raise "The code #{@val.ord} is not supported" unless result
                "\\#{result}"
            end
=begin rdoc
Instance to printable, delegates to +toDataMetaForm+
=end
            def to_s; toDataMetaForm end
        end

=begin rdoc
Format model token - field

@!attribute [r] name
    @return [String] field name in this position

@!attribute [r] fmt
    @return [String] field Format in DataMetaForm terms, any other format like AbInitio format or Ruby format should be
        converted to DataMetaForm and, if necessary, back.

@!attribute [r] isReq
    @return [Boolean] +true+ if the field is required, +false+ if the field is optional.

=end
        class Field < FmtItem
            attr_reader :name, :fmt, :isReq
            def initialize(name, isReq, fmt = nil )
                @name, @fmt, @isReq = name, fmt, isReq
            end
=begin rdoc
Transforms the instance into DataMetaForm source code
@return [String] DataMetaForm source for the instance
=end
            def toDataMetaForm
                result = "#{@isReq ? '+' : '-'}#{name}"
                result << %Q<|#{fmt}|> if fmt
                result
            end

=begin rdoc
Instance to printable, delegates to +toDataMetaForm+
=end
            def to_s; toDataMetaForm end
        end

=begin rdoc
The whole object model of format specification.
=end
        class Model
=begin rdoc
Creates an instance, initializes internal structures.
=end
            def initialize; @items = [] end

=begin rdoc
Appends an item to the model.
@param [FmtItem] item the item to append
@raise [ArgumentError] if the item is not an instance of {FmtItem}
@return [Model] self for call chaining
=end
            def <<(item)
                raise ArgumentError, "'#{item.class}' passed where FmtItem expected" unless item.kind_of?(FmtItem)
                @items << item
                self
            end

=begin rdoc
Regular Ruby iterating eaach.
=end
            def each
                @items.each {|x| yield x}
            end

=begin rdoc
Get a copy of all the items on the instance. The caller can do whatever with the copy.
=end
            def items; @items.clone end

=begin rdoc
Exports the model into DataMetaForm source.
=end
            def toDataMetaForm
                result = <<DATAMETAFORM_HEADER
/*
  Backspace codes specified as standard ASCII:
  http://www.december.com/html/spec/ascii.html

  There may be extra codes introduced later
*/
record
DATAMETAFORM_HEADER
                indent = ' ' * 4
                @items.each { |i|
                    result << indent << i.toDataMetaForm
                    result << "\n" if i.kind_of?(Field) # skip a line for a field for looks
                }
                result << "\n" unless result[-1..-1] == "\n"
                result << "end\n"
            end

        end # class Model

=begin rdoc
Initializes environment by loading all relevant rules.
=end
        def loadFormRules
            DataMetaParse.loadBaseRulz
            Treetop.load(File.join(File.dirname(__FILE__), '..', '..', 'grammar', 'ptf'))
        end
=begin rdoc
Parses the DataMetaForm source, returns the instance of the {Model}
@param [String] source the source DataMetaForm code to parse
@return [Model] the DataMetaForm model parsed from the source.
=end
        def parse(source)
            ast = DataMetaParse.parse(DataMetaFormParser.new, source)
            raise "This source code is not a valid DataMetaForm code:\n#{source}"  unless ast
            raise ast if ast.is_a?(DataMetaParse::Err)
            model = Model.new

            ast.flds.elements.each { |item| # each fields list item
                fli = item.fli
                case fli.type
                    when 'delim'
                        model << Delim.fromDataMetaForm(fli.sym.text_value)
                    when 'fs'
                        model << Field.new(fli.fieldName.text_value, fli.orf.isReq, fli.fmt)
                    else
                        # none of the interest
                end
            }
            model

        end
        module_function :parse, :loadFormRules
    end # module Fmt
end
