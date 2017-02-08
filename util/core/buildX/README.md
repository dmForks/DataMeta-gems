# dataMetaBuild

Utilities for building and deploying applications and gems.

References to this gem's:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems)

## DESCRIPTION:

See the [DataMeta Project](https://github.com/eBayDataMeta/DataMeta).

## FEATURES/PROBLEMS:

* None

## SYNOPSIS:

### Maven dependencies artifacts local paths

To distribute a Java application, you may need a list of paths to the app dependency JARs.

To build such list for a Maven project, use the `dataMetaMvnDepsPaths.rb` runnable on this gem.

Ran in the directory with the `pom.xml` for the project, it would output a file with
the name <tt>dataMetaMvnDepsPaths.</tt><i>scope</i> for each of the scope used in the project **except** `system` , for example:

```
dataMetaMvnDepsPaths.compile
dataMetaMvnDepsPaths.test
dataMetaMvnDepsPaths.runtime
```

You can specify a different file prefix in the first parameter to the runnable.

Each file would have a full path to a dependency artifact on each line for all dependencies in the scope, for example:

```
/home/uid/.m2/repository/junit/junit/4.11/junit-4.11.jar
```

The script will look for your local Maven repository in your `$HOME/.m2/repository` which is pretty much hard-set
for Maven.

Those files can be used for deployment scripts, for cross-project dependency analysis etc.

## REQUIREMENTS:

* No special requirements

## INSTALL:

    gem install dataMetaBuild

## LICENSE:

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)

