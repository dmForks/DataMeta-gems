$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

%w(fileutils set).each { |r| require r }

module DataMetaDom

=begin rdoc
All sources including all includes from the master file.

For command line details either check the new method's source or the README.rdoc file, the usage section.
=end
class Sources

=begin rdoc
Start parsing from the master file, collect all the files that are included.
=end
    def initialize(masterFile)
        masterPath = File.dirname(masterFile)
        @todo = {}; @done = {}
        libSpec = ENV[DATAMETA_LIB]
        @paths = libSpec ? libSpec.split(File::PATH_SEPARATOR).map { |e| uniPath(e) } : []
        @paths.unshift(masterPath).flatten! if masterPath
        @paths.unshift '.' # start looking in the current directory and then in the rest of the path
        src = SourceFile.new(masterPath, File.basename(masterFile))
        @todo[src.key] = src
    end

=begin rdoc
Returns the set of the keys of the source files alredy parsed.
=end
    def doneKeys; @done.keys end

=begin rdoc
Fetches the instance of SourceFile by its key.
=end
    def [](key); @done[key] end

# Queue a source file for parsing
    def queue(name)
        # need to resolve the name to the path first
        includeDir = nil
        @paths.each { |m|
            fullName = "#{m}#{File::SEPARATOR}#{name}"
            if File.exist?(fullName)
                includeDir = m
                break
            end
        }
        raise "Missing include '#{name}' in the path #{@paths.join(File::PATH_SEPARATOR)}" unless includeDir
        src = SourceFile.new(includeDir, name)
        @todo[src.key]=src unless @todo[src.key] || @done[src.key]
        self
    end

=begin rdoc
Returns next source file in queue if any, returns +nil+ if no more source files left to parse.
=end
    def next
        return nil if @todo.empty?
        @key = nil
        @todo.each_key { |k| @key = k; break }
        @val = @todo[@key]
        @todo.delete @key; @done[@key] = @val
        @val
    end
end

end
