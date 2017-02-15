# DataMetaAvro

DataMeta [Avro](http://avro.apache.org/docs/current) utilities, such as DataMetaDOM source to
[Avro Schema](http://avro.apache.org/docs/current/spec.html) converter.

References to this gem's:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems)


## DESCRIPTION:

See the [DataMeta Project](https://github.com/eBayDataMeta/DataMeta).

## FEATURES/PROBLEMS:

Avro support:

* ver `1.8.1` or newer

Since Avro supports limited subset of the DataMetaDOM features, DataMeta's features that are not supported by Avro
cause an error during export.

## SYNOPSIS:

### Avro schema generator

Since DataMeta DOM is superset of Avro data types, tradeoffs are made:

* The DataMeta `datetime` is converted to an integral type as described in the [Avro Schema Docs](http://avro.apache.org/docs/current/spec.html#Time+%28millisecond+precision%29)
* The DataMeta aggregate types `set`, `deque`, `list` all converted to [Avro arrays](http://avro.apache.org/docs/current/spec.html#Arrays).
* Since Avro allows strings only as map keys, an attempt to convert a DataMeta DOM with a mapping with keys other than
    `string` will cause an error.
* The DataMeta type `numeric` will cause an error during conversion.

* Runnables:
  * <tt>dataMetaAvroSchemaGen.rb</tt> - generate [Avro](http://avro.apache.org/docs/current) [Schemas](http://avro.apache.org/docs/current/spec.html),
    one file per class

Usage:

    dataMetaAvroSchemaGen.rb <DataMetaDOM source> <Avro Schemas target dir>

## REQUIREMENTS:

* No special requirements

## INSTALL:

    gem install dataMetaAvro

## LICENSE:

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)
