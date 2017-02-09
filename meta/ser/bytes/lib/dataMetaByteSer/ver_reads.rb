$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'dataMetaDom/field'
require 'dataMetaDom/pojo'

module DataMetaByteSer
=begin rdoc
Migration tooling.

=end
module VerReads
    include DataMetaDom, DataMetaDom::PojoLexer
=begin
Generates Versioned Read switch that channels the read to the proper migration scenario.
=end
    def genVerReadSwitch(v1, v2, modelForVer, vers, outRoot)
#        v1 = mo1.records.values.first.ver.full
#        v2 = mo2.records.values.first.ver.full
        mo1 = modelForVer.call(v1)
        mo2 = modelForVer.call(v2)
        destDir = outRoot
        javaPackage = '' # set the scope for the var
        vars = OpenStruct.new # for template's local variables. ERB does not make them visible to the binding
        # sort the models by versions out, 2nd to be the latest:
        raise ArgumentError, "Versions on the model are the same: #{v1}" if v1 == v2
        if v1 > v2
            model2 = mo1
            model1 = mo2
            ver1 = v2
            ver2 = v1
        else
            model2 = mo2
            model1 = mo1
            ver1 = v1
            ver2 = v2
        end
        puts "Going from ver #{ver1} to #{ver2}"
        trgE = model2.records.values.first
        javaPackage, baseName, packagePath = assertNamespace(trgE.name)
        javaClassName = "Read__Switch_v#{ver1.toVarName}_to_v#{ver2.toVarName}"
        destDir = File.join(outRoot, packagePath)
        FileUtils.mkdir_p destDir
        IO::write(File.join(destDir, "#{javaClassName}.java"),
                  ERB.new(IO.read(File.join(File.dirname(__FILE__), '../../tmpl/readSwitch.erb')),
                          $SAFE, '%<>').result(binding), mode: 'wb')
    end
    module_function :genVerReadSwitch
end
end
