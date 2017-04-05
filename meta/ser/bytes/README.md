# `dataMetaByteSer` gem

Byte array (de)serialization generation from [DataMeta DOM](https://github.com/eBayDataMeta/DataMeta-gems/tree/master/meta/core/dom) sources.

References to this gem's:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems/tree/master/meta/ser/bytes)


## DESCRIPTION:

See the [DataMeta Project Documentation Repository](https://github.com/eBayDataMeta/DataMeta)

## FEATURES:

Generates (de)serializers to/from byte arrays with matching Hadoop writables, performance maximized by storage size
first and runtime performance second, both aspects are clocked to perform around best in the class.

## SYNOPSIS:

To generate Byte Array serializers in Java, including Hadoop Writables for the DataMeta model, run:

    dataMetaByteSerGen.rb <DataMeta DOM source> <Target Directory>

## REQUIREMENTS:

* No special requirements

## INSTALL:

    gem install dataMetaByteSer

## LICENSE:

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)
