## dataMetaPii

The PII (Personally Identifiable Information) registry support: master data field definition and link to using those to
applications/services code.

References to this gem's:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems)

## DESCRIPTION:

This gem provides:

* The [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) to describe PII fields definition with properties
    such as impact level and any other properties you may want to add.
* And another [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) to describe how the PII fields are related
    to the application/services code.
    such as impact level and any other properties you may want to add.
* Parsers for the [DSLs](https://en.wikipedia.org/wiki/Domain-specific_language)&uarr;
* Exporters of the PII definition fo Java, Scala, Python and JSON.

## FEATURES/PROBLEMS:

The gem features the API and the executable for the code export.

## SYNOPSIS:

### Code Export

The Gem has the executable named `dmPiiGenCode.rb` which is used to export
DataMetaPII definitions into different formats.

The executable's help text you get by running `dmPiiGenCode.rb` without arguments
looks like this:

```
Usage: dmPiiGenCode.rb <Scope> <ExportFormat> <OutputRoot> [ Namespace ]

Exports the PII definition into sources

Parameters:
   <Scope> - one of: abstract, app

   <ExportFormat>  - one of: java, scala, python, json

   <OutputRoot> - must be a valid directory in the local file system.

   [ Namespace ] - for Java and Scala - package name, for Python - module name, for JSON - does not matter.

   DataMetaPII sources should be piped in.

```

Therefore, to export the version `1.0.0` of the Abstract Fields master to 
JSON into current directory, you would run:

```
cat abstract-1.0.0.dmPii | piiGenCode.rb abstract json .
```

Which would write a file named `PiiAbstractDef_1_0_0.json` in current directory.

### AppLink API

The gem provides the AppLink DSL parsing API to obtain the data structure describing the AppLink 
and use it to generate code.

Run `DataMetaPii.parseAppLink(source)` to get the AppLink data structures in memory

## INSTALL:

    gem install dataMetaPii

## LICENSE:

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)

