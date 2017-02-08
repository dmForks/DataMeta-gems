
module DataMetaXtra

=begin rdoc
File System utilities.
=end
    module FileSys

=begin rdoc
FileSystem Entry
=end
        class FsEntry
=begin rdoc
Entyr type - file.
=end
            FILE_TYPE = :f
=begin rdoc
Entyr type - directory.
=end
            DIR_TYPE = :d

        end

=begin rdoc
A set of permissions: any mix of read, write and execute, including all set to false.
@!attribute [rw] r
    @return [Boolean] read access, true or false
@!attribute [rw] w
    @return [Boolean] write access, true or false
@!attribute [rw] w
    @return [Boolean] execute access, true or false

=end
        class Perm
            attr_accessor :r, :w, :x

# POSIX Read permission mask: binary 100
            READ_MASK = 4

# POSIX Write permission mask: binary 010
            WRITE_MASK = 2

# POSIX Execute permission mask: binary 1
            EXEC_MASK = 1
=begin rdoc
Unix {http://en.wikipedia.org/wiki/Sticky_bit Sticky bit},
the +S_ISVTX+ mask (or +S_ISTXT+ in BSD) defined in
{http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_stat.h.html sys/stat.h}.
Use with caution because the semantics is fuzzy and, by some is considered obsolete.
=end
            STICKY_MASK = 01000

=begin rdoc
Unix +S_ISUID+ flag defined in {http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_stat.h.html sys/stat.h}
which sets the owner's ID on executable regardless of who actually activates the executable.
See {http://en.wikipedia.org/wiki/Setuid this article for details.}
=end
            USER_ID_EXE_MASK = 04000

=begin rdoc
Unix +S_ISGID+ flag defined in {http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_stat.h.html sys/stat.h}
which sets the owner's ID on executable regardless of who actually activates the executable.
See {http://en.wikipedia.org/wiki/Setuid this article for details.}
=end
            GROUP_ID_EXE_MASK = 02000

            def initialize(r, w, x)
                @r, @w, @x = r, w, x
            end

=begin rdoc
Standard Ruby object equality method for hashes and sets.
=end
            def eql?(other)
                self.r == other.r && self.w == other.w && self.x == other.x
            end

=begin rdoc
Redefine equality operator for simple comparison, not delegated to {#eql?}, code simply repeated here
for speed
=end
            def ==(other)
                self.r == other.r && self.w == other.w && self.x == other.x
            end
=begin rdoc
Creates an instance from textual specification, up to tree letters +r+, +w+, +x+ in any order,
'<tt>r</tt>' for 'read', '<tt>w</tt>' for 'write', '<tt>x</tt>' for 'execute.
Letter present turns the setting on, letter absent turns it off.
@param [String] specs String of letters as described or a Fixnum with usual Posix bitmask: 4 for read, 2 for write, 1 for exec.
@raise [ArgumentError] if the specs contain invalid character when specified as a String or if it does not fall into the range
    between 0 and 7 inclusively if passed as a Fixnum
@return [Perm] instance per the specs
=end
            def self.of(specs)
                result = Perm.new(false, false, false)
                case
                    when specs.kind_of?(String)
                        specs.each_char { |c|
                            case c
                                when 'r'
                                    result.r = true
                                when 'w'
                                    result.w = true
                                when 'x'
                                    result.x = true
                                else
                                    raise ArgumentError, %<Illegal perms letter "#{c}" in the string of "#{specs}">
                            end
                        }
                    when specs.kind_of?(Fixnum)
                        raise ArgumentError, %<Illegal perm mask value of #{specs}> if specs < 0 || specs > 7
                        result.r = true if specs & READ_MASK != 0
                        result.w = true if specs & WRITE_MASK != 0
                        result.x = true if specs & EXEC_MASK != 0
                    else
                        raise ArgumentError, %<Illegal specs: "#{specs.inspect}">
                end
                result
            end

=begin rdoc
Turns the permission into the 'rwx' format for brevity and serialization
=end
            def toRwx
                result = ''
                result << 'r' if r
                result << 'w' if w
                result << 'x' if x
                result
            end

=begin rdoc
Turns the permission into the bitmask format for brevity and serialization
=end

            def to_i
                result = 0
                result |= READ_MASK if r
                result |= WRITE_MASK if w
                result |= EXEC_MASK if x
                result
            end
=begin rdoc
Convenient instance - all perms
=end
            ALL = Perm.new(true, true, true)

=begin rdoc
Convenient instance - no perms
=end
            NONE = Perm.new(false, false, false)

=begin rdoc
Convenient instance - read only
=end
            R = Perm.new(true, false, false)

=begin rdoc
Convenient instance - write only
=end
            W = Perm.new(false, true, false)

=begin rdoc
Convenient instance - read/write
=end
            RW = Perm.new(true, true, false)

=begin rdoc
Convenient instance - read and exec
=end
            RX = Perm.new(true, false, true)
# Not providing constants for just exec and write+exec, those are not very useful and hardly ever seen.

=begin rdoc
Creates an instance with 3 booleans: read, write, exec
=end
        end

=begin rdoc
POSIX access perms - per system, user, group and world

@!attribute [rw] s
    @return [Perm] Sticky flag

@!attribute [rw] u
    @return [Perm] user perms

@!attribute [rw] g
    @return [Perm] group perms

@!attribute [rw] a
    @return [Perm] world perms (all)
=end
        class PosixPerms
            attr_accessor :s, :u, :g, :a
=begin rdoc
Parses the {Perm} instance from the given source.

@param [String] source either a String or a Fixnum a {Perm} or +nil+, see the method {Perm.of} for details.
@param [String] kind the kind of the permissions for diagnostics, like 'user', 'group', 'world' or 'system'
@return [Perm] instance according to the description
@raise [ArgumentError] if the specs contain invalid character in case of a String or if the source is neither
    a String nor a {Perm} nor +nil+
=end
            def self.from(source, kind)
                case
                    when source.kind_of?(NilClass) || source.kind_of?(Perm)
                        source
                    when source.kind_of?(String) || source.kind_of?(Fixnum)
                        Perm.of(source)
                    else
                        raise ArgumentError, %<For #{kind} perms, invalid perm source: #{source.inspect} >
                end
            end

=begin rdoc
Creates an instance
@param [String] user user permissions, can be passed as {Perm} object or String or Fixnum, see the method {PosixPerms.from} for details.
@param [String] group group permissions, can be passed as {Perm} object or String or Fixnum, see the method {PosixPerms.from} for details.
@param [String] world world permissions, can be passed as {Perm} object or String or Fixnum, see the method {PosixPerms.from} for details.
@param [String] sticky flag, can be passed as {Perm} object or String or Fixnum, see the method {PosixPerms.from} for details.
=end
            def initialize(user, group, world, sys = nil)
                @u = PosixPerms.from(user, 'user')
                @g = PosixPerms.from(group, 'group')
                @a = PosixPerms.from(world, 'world')
                @s = PosixPerms.from(sys, 'system')
            end

=begin rdoc
Standard Ruby object equality method for hashes and sets.
=end
            def eql?(other)
                self.u == other.u && self.g == other.g && self.a == other.a && self.s == other.s
            end
=begin rdoc
Redefine equality operator for simple comparison, not delegated to {#eql?}, code simply repeated here
for speed
=end
            def ==(other)
                self.u == other.u && self.g == other.g && self.a == other.a && self.s == other.s
            end

=begin
Converts to integer POSIX specification, 3 bits per each of User, Group, All aka World aka Others
=end
            def to_i; ('%d%d%d' % [@u, @g, @a]).to_i(8) end

        end

=begin rdoc
Generic Id and Name pair, good for any such situation, but in this case used specifically for POSIX user/group ID+Name.

Regarding equality of these instances, it's better to use one of the components straight, although the both the {#eql?}
and <tt>==</tt> method override are provided.

@!attribute [rw] id
    @return [Fixnum] numeric ID associated with the name.

@!attribute [rw] name
    @return [String] the name associated with the ID

=end
        class IdName
            attr_accessor :id, :name

=begin rdoc
Name-only instance, id set to nil. Useful for cases when ID is irrelevant, such as transferring directory structure
between hosts.
@raise [ArgumentError] if the name string is empty or contains invalid characters
@param [String] name the {#name}
=end
            def self.forName(name)
                IdName.new(nil, name)
            end

=begin rdoc
Convenience constructor
@raise [ArgumentError] if the name string is empty or contains invalid characters
=end
            def initialize(id, name)
                raise ArgumentError, %<Invalid POSIX name: "#{name}"> unless name =~ /^[a-z][\w\.-]*$/
                @id, @name = id, name
            end

=begin rdoc
Standard Ruby object equality method for hashes and sets.
=end
            def eql?(other)
                self.id == other.id && self.name == other.name
            end
=begin rdoc
Redefine equality operator for simple comparison, not delegated to {#eql?}, code simply repeated here
for speed
=end
            def ==(other)
                self.id == other.id && self.name == other.name
            end
        end

=begin rdoc
POSIX ownership information - group and the user
=end
        class PosixOwn
            attr_accessor :g, :u
=begin rdoc
@param [String] source either a String or a {IdName} or +nil+, see the method {IdName.forName} for details.
@param [String] kind the kind of the ownership for diagnostics, user or group
@return [IdName] instance according to the description
@raise [ArgumentError] if the specs contain invalid character in case of a String or if the source is neither
    a String nor a {Perm} nor +nil+

=end
            def self.from(source, kind)
                case
                    when source.kind_of?(NilClass) || source.kind_of?(IdName)
                        source
                    when source.kind_of?(String)
                        IdName.forName(source)
                    else
                        raise ArgumentError, %<For #{kind} ownership, invalid ownership source: #{source.inspect} >
                end
            end
=begin rdoc
Convenience constructor
@param [IdName] user either the IdName instance or a string, in case of a string, see {IdName.forName}
=end
            def initialize(user, group = nil)
                @u = PosixOwn.from(user, 'user')
                @g = PosixOwn.from(group, 'group')
            end
        end
    end
end

