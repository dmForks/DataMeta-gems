$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'fileutils'

=begin rdoc

Utilities for building and deploying applications.

@!attribute [rw] target
    @return [String] build target directory name.
    @see TARGET_DIR
=end

class DataMetaBuild
    # Current version
    VERSION = '1.0.0'

# Default build target directory, to mimic Maven it's literally "<tt>target</tt>".
    TARGET_DIR = 'target'

    attr_accessor :target

    # Initializes the instance with the given target directory, defaulted to TARGET_DIR
    def initialize(target = TARGET_DIR); @target = target end

    # Creates target if it does not exist.
    def init; FileUtils.mkpath target end

    # Removes target if it exists.
    def clean
      FileUtils.remove_dir(target, true) if File.exists? target_dir
    end

end
