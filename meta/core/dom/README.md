# dataMetaDom

The Core of the DataMeta platform, see the Features section below.

## Description

See the [DataMeta home page](https://github.com/eBayDataMeta) and

References to this gem's source:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems/tree/master/meta/core/dom)

## Features

The following components are included into this gem:

* DataMetaDOM DDL parser - parses the DataMetaDOM [DDL](http://en.wikipedia.org/wiki/Data_definition_language) into
  the model in memory.
* export the DataMetaDOM DDL to [POJO](http://en.wikipedia.org/wiki/Plain_Old_Java_Object) including implementors
  of the `DataMetaSame` Java interface, to provide equality either by the class `identity` or by all of the
  fields.
* export the DataMetaDOM DDL to MySQL DDL

## Problems

None known.

## Synopsis

Beside the API, there are the following runnables in this gem:

### DataMetaDOM POJO generator.

Use this runnable to parse a DataMetaDOM source and generate Java objects
([POJOs](http://en.wikipedia.org/wiki/Plain_Old_Java_Object)) matching the DataMeta model.

Usage:

    dataMetaDomPojo.rb <DataMetaDOM source> <target directory>

Example:

    dataMetaDomPojo.rb /gitrepos/projects/data/schema/showCase.dmDom ./pojos

### DataMetaDOM MySQL DDL generator

Use this runnable to parse a DataMetaDOM DDL source and generate matching
[MySQL DDL](http://dev.mysql.com/doc/refman/5.5/en/sql-syntax-data-definition.html) statements, including
creates, drops, creating referential integrity links and dropping those.

Usage:

    dataMetaDomMySqlDdl.rb <DataMetaDOM source> <target directory>

Example:

    dataMetaDomMySqlDdl.rb /gitrepos/projects/data/schema/showCase.dmDom ./sql

### DataMetaDOM Full compare DataMetaSame generator for POJOs

Use this to generate implementors of the DataMetaSame interface from DataMetaDOM sources performing full compare.

Usage:

    dataMetaDomSameFullJ.rb <DataMetaDOM source> <target directory>

### DataMetaDOM compare by identity DataMetaSame generator for POJOs

Use this to generate implementors of the DataMetaSame interface from DataMetaDOM sources performing compare only
by the `identity` for the class, see DataMetaDom::Record for details.

Usage:

    dataMetaDomSameIdJ.rb <DataMetaDOM source> <target directory>

### Exporting DataMetaDOM source into graphical file showing entity relationships

This script generates [GraphViz](http://www.graphviz.org) source for the given DataMetaDOM module
and attempts to display the resulting jpeg file in the current OS.

Usage:

    dataMetaDomGvExport.rb <DataMetaDOM source> <target base path>

The script will append the suffix `.gv` to the `target base path` for the GraphViz source and the suffix `.jpeg`
to the name of the genrated image file.

Example:

    dataMetaDomGvExport.rb src/main/schema/Model.dmDom target/Model

this will generate `target/Model.gv` and `target/Model.jpeg`

This requires [GraphViz](http://www.graphviz.org) installation with the `dot` command in the path
and some kind of a graphic environment. On Windows, [Irfanview](http://www.irfanview.com) is very useful, otherwise
the script will use default Windows viewers that oftentimes are much slower.

### Reversion all files in path

Usage:

    dataMetaReVersion.rb <Path> <NS> <CSV-globs> <Ver-From> <Ver-To>

Where:

* Path - starting path to look for the files to re-version
* NS - Namespace, such as Java/Scala package
* CVS-globs - comma-separated file patterns, in regular filesystem globbing format
* Ver-From - Source version or an asterisk for any version. Example: `11.2.1`
* Ver-To - Target version. Example: `11.2.2`

Examples of arguments to this command:

* `src/main/com/acme com.acme.svc.obj.dom '*.java,*.scala' '*' 1.2.3` -- starting from the `src/main/com/acme`
    directory, replace on all Scala and Java files, any DataMeta version with `1.2.3`
* `. com.acme.svc.obj.dom '*.conf,*.scala' 1.2.1 1.2.3` -- starting from the current directory,
    replace on all Scala and config files, DataMeta version `1.2.1` with `1.2.3`.

Note the single quotes for the file glob patterns and the "star" specification of the source version: this is to
prevent the shell to glob before passing the result to the program.

Note that there is no relation between the path and the namespace; only Java still enforces such relation therefore
we do not want to be dependent on it.


## Requirements

* No special requirements

## Install

    gem install dataMetaDom

## License

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)

