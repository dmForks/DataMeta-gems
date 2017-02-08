$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set).each { |r| require r }

module DataMetaDom

=begin
Converter (ser/deser) code common to the DataMeta DOM.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end

=begin rdoc
Converter class definition, see implementations:
* INTEGRAL_CONV
* FRACT_CONV
* BOOL_CONV
* DTTM_CONV
* TEXT_CONV
=end
class Converter

=begin rdoc
Lambda converting from a data type to matching textual.
=end
    attr_reader :ser

=begin rdoc
Lambda converting from a textual to matching data type.
=end
    attr_reader :deser

=begin rdoc
Creates an instance with the given parameters, two lambdas, see ser and deser properties for details.
=end
    def initialize(serialize, deserialize); @ser = serialize; @deser = deserialize end
end

=begin rdoc
Converter for the integral types, meaning no fraction.
=end
INTEGRAL_CONV=Converter.new(lambda { |i| i ? i.to_s : nil }, lambda { |s| s ? s.to_i : nil })

=begin rdoc
Numbers with fraction, such as real numbers, aka floating point.
=end
FRACT_CONV=Converter.new(lambda { |f| f ? f.to_s : nil }, lambda { |s| s ? s.to_f : nil })

=begin rdoc
Converter for boolean.
=end
BOOL_CONV=Converter.new(lambda { |b| b ? b.to_s : nil },
                        lambda { |s| s && !s.empty? ? ("TY1ty1".index(s[0]) ? true : false) : nil })
=begin rdoc
Converter for datetime.
=end
DTTM_CONV=Converter.new(lambda { |d| d ? "DateTime.parse('#{d}')" : nil }, lambda { |s| s ? DateTime.parse(s) : nil })
# DateTime.to_s does exactly what we need, no more no less

=begin rdoc
Conterter for textual types, such as string or char.
=end
TEXT_CONV=Converter.new(lambda { |src| src.inspect }, lambda { |src| eval(src) })

# All Converters hash keyed by the type, referencing an instance of the Converter class.
CONVS={INT => INTEGRAL_CONV, STRING => TEXT_CONV, CHAR => TEXT_CONV, FLOAT => FRACT_CONV, NUMERIC => FRACT_CONV,
       BOOL => BOOL_CONV, DATETIME => DTTM_CONV, URL => TEXT_CONV}


end
