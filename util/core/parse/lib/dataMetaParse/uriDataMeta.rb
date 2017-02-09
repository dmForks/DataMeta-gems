$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'uri'
require 'treetop'

module DataMetaParse
=begin rdoc
DataMeta URI with all the parts.

The user story:

* DataMeta URIs are used in DataMeta Scripts to specify all aspects of a data set identity and location.
* For physical access, a URI may be disassembled using this grammar and parser, the parts obtained so may be used
  to access concrete physical resources.

@!attribute [r] proto
    @return [String] the protocol part, such as +http+, +ftp+, +socparc+ etc

@!attribute [r] user
    @return [String] the user id part of the URI, can be +nil+ and for some URIs may be in properties

@!attribute [r] pwd
    @return [String] the password part of the URI, can be +nil+ and for some URIs may be in properties

@!attribute [r] host
    @return [String] the host part of the URI

@!attribute [r] port
    @return [Fixnum] the port number specified in the URI, can be +nil+

@!attribute [r] path
    @return [String] for the +file+ protocol, path as specified, full or relative. For any other URI, the part between
        the closing '/' after the +host:port+ part and the query part starting with '?'.
        This means, for all other protocols except +file+, the path part will never have an initial slash.

@!attribute [r] props
    @return [Hash] hash of properties keyed by the property name and pointing to a value if any

=end
    class Uri
        attr_reader :proto, :user, :pwd, :host, :port, :path, :props

=begin rdoc
Creates an instance of the object.

@param [String] proto see the property {#proto}
@param [String] user see the property {#user}
@param [String] pwd see the property {#pwd}
@param [String] host see the property {#host}
@param [String] port see the property {#port}
@param [String] path see the property {#path}
@param [String] props see the property {#props}
=end
        def initialize(proto, user, pwd, host, port, path, props)
            raise ArgumentError, 'Password specified but user not' if !user && pwd
            raise ArgumentError, 'For file protocol, only path can be specified' if proto == 'file' && (
                user || pwd || host || port || !props.empty?)

            @proto, @user, @pwd, @host, @port, @path, @props = proto, user, pwd, host, port, path, props
        end

=begin rdoc
Equality to the other
=end
        def ==(other)
            @proto == other.proto && @user == other.user && @pwd == other.pwd && @host == other.host &&
                    @port == other.port && @path == other.path && @props.eql?(other.props)
        end

=begin rdoc
Same as the {#==}
=end
        def eql?(other); self == other end

=begin rdoc
Loads the grammar - has to be done only once per RVM start. Relies on loading the basics.
=end
        def self.loadRulz
            Treetop.load(File.join(File.dirname(__FILE__), 'urlDataMeta'))
        end

=begin rdoc
Instance to textual.
=end
        def to_s
            if @proto == 'file'
                "file://#{@path}"
            else
                result = ''
                result << @proto << '://'
                result << URI.encode_www_form_component(@user) if @user
                result << ':' << URI.encode_www_form_component(@pwd) if @user && @pwd
                result << '@' if @user
                result << @host
                result << ':' << @port.to_s if @port
                result << '/' if @path || !@props.empty?
                result << @path if @path

                result << '?' << @props.keys.map { |k|
                    v=@props[k]; v ? "#{k}=#{URI.encode_www_form_component(v)}" : "#{k}"
                }.join('&') unless @props.empty?

                result
            end
        end

=begin rdoc
Parses the source into the instance of the object.
@param [String] source the source, the URI specification to parse into the instance of this class
=end
        def self.parse(source)
            fileSignature = 'file://'
            if source.start_with?(fileSignature)
                Uri.new('file', nil, nil, nil, nil, source[fileSignature.length..-1], {})
            else
                parser = DataMetaUrlParser.new
                ast = parser.parse(source)
                return nil unless ast
                proto = ast.proto.text_value
                user = ast.user? ? ast.userPwd.user.text_value : nil
                pwd = ast.pwd? ? URI.decode_www_form_component(ast.userPwd.password) : nil
                host = ast.host.text_value
                port = ast.port? ? ast.port.number : nil
                path = ast.path? ? ast.uTail.path : nil
                query = ast.query? ? ast.uTail.query : nil
                props = {}
                if query
                    pairs = query.split('&')
                    pairs.each { |pairString|
                        key, val = pairString.split('=')
                        props[key] = val ? URI.decode_www_form_component(val) : nil # this is caused by &paramA&paramB=b, in which case paramA will be nil
                    }
                end
                Uri.new(proto, user, pwd, host, port, path, props)
            end
        end

    end
end
