$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module DataMetaDom

=begin rdoc
Helper method for runnables.

Prints help and exits placing the purpose of the runnable and the parameters description in proper spots.

Exits with code 0 if errorText is +nil+, exits with code 1 otherwise. Prints errorText with
proper dressing to the +STDERR+.
=end
def help(file, purpose, params, errorText = nil)
    puts <<HELP
DataMeta DOM version #{DataMetaDom::VERSION}

#{purpose}. Usage: #{File.basename(file)} #{params}

HELP

$stdout.flush # otherwise it may mix up with the $stderr output below
$stderr.puts "\nERROR: #{errorText}" if errorText
exit errorText ? 0 : 1
end

# Shortcut to help for the Pojo Generator.
def helpPojoGen(file, errorText=nil)
    help(file, 'POJO generator', '<DataMeta DOM source> <target directory>', errorText)
end

# Shortcut to help for the Pojo Generator.
def helpScalaGen(file, errorText=nil)
    help(file, 'Scala generator', '<DataMeta DOM source> <target directory>', errorText)
end

# Shortcut to help for the MySQL DDL Generator.
def helpMySqlDdl(file, errorText=nil)
    help(file, 'MySQL DDL generator', '<DataMeta DOM source> <target directory>', errorText)
end

# Shortcut to help for the Oracle DDL Generator.
def helpOracleDdl(file, errorText=nil)
    help(file, 'Oracle DDL generator', '<DataMeta DOM source> <target directory>', errorText)
end

module_function :help, :helpPojoGen, :helpMySqlDdl, :helpScalaGen
end
