#!/usr/bin/env ruby
# Build path lists for the Maven project in the current directory

require 'open3'
require 'set'

H1 ||= '*' * 15

# Collectable Maven scopes: http://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
SCOPES = Set.new %W(compile runtime test)
# provided, system, import are not intresting for deployment

MVN_LOCAL_REPO = File.join(ENV['HOME'], '.m2', 'repository')

raise ArgumentError, %|Maven local repository "#{
    MVN_LOCAL_REPO}" is not a directory on the local filesystem| unless File.directory?(MVN_LOCAL_REPO)

@outFileNamePfx = $*[0] || "#{File.basename(__FILE__)[/[^\.]+/]}"

OUTS = Hash.new { |h,k| h[k] = File.open("#{@outFileNamePfx}.#{k}", mode: 'wb')}

@srcLine = nil
@lineNum = 0

class Dep
    attr_reader :group, :artifact, :packaging, :version, :scope, :classifier

    class << self
        def parse(source)
            depParts = source.split(/\s+/)[1].split(':')
            case depParts.length
                when 5
                    grp, art, pack, ver, scp = depParts
                    clz = nil
                when 6
                    grp, art, pack, clz, ver, scp = depParts
                else
                    raise ArgumentError, "Unsupported dependencies format, arr=#{depParts.inspect}"

            end
            Dep.new(grp, art, pack, ver, scp, clz)
        end
    end

    def initialize(group, artifact, packaging, version, scope, classifier = nil)
        @group, @artifact, @packaging, @version, @scope, @classifier = group, artifact, packaging, version, scope, classifier
        %W(group artifact packaging version scope).each { |varName|
            v = instance_variable_get('@' + varName)
            raise ArgumentError, %|The value for <#{varName}> is missing| unless v && !v.empty?
        }
    end

    def toPath
        fullPath = File.join(MVN_LOCAL_REPO, @group.split('.'), @artifact, @version, "#{
            @artifact}-#{@version}#{@classifier ? '-' + @classifier : ''}.#{@packaging}")
        # Make sure it actually resolves to a valid file on the local FS, unless it's in the system scope
        #  that can be anywhere and are of little concern
        raise ArgumentError, %|"#{fullPath}" is not a file| unless File.file?(fullPath)
        fullPath
    end
end

cmd = 'mvn dependency:list'
puts %|Running "#{cmd}"|
o,e,s= Open3.capture3(cmd)

 unless s.to_i == 0
     puts %|#{H1} OUT #{H1}
#{o}
#{H1} ERR #{H1}
#{e}
#{H1} state=#{s.inspect}
|
     raise RuntimeError, %|ERRORS running "#{cmd}"|
end

@stage = :init
@exitCode = 0
o.split("\n").each { |line|
    begin
        @srcLine = line.strip
        @lineNum += 1
        case @stage
            when :init
                @stage = :parse if %r{^\[INFO\]\s+The following files have been resolved:$} =~ @srcLine
            when :parse
                break if @srcLine == '[INFO]'
                dep = Dep.parse(@srcLine)
                OUTS[dep.scope].puts dep.toPath if SCOPES.member?(dep.scope)
            else
                raise RuntimeError, %|Unsupported stage "#{@stage}"|
        end

    rescue Exception => x
        $stderr.puts %|ERROR while processing line ##{@lineNum}: >>>#{@srcLine}<<<\n#{x.message}\n#{x.backtrace.join("\n")}|
        @exitCode = 1
        break
    end

}

OUTS.values.each {|f| f.close}
exit @exitCode if @exitCode != 0
puts "Saved dependency path list to:\n\t#{OUTS.values.map{|f| f.path}.join("\n\t")}\nDone."
