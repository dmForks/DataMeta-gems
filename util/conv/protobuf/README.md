# DataMetaProtobuf

DataMeta [Protobuf](https://github.com/google/protobuf/wiki) utilities, such as DataMetaDOM source to
[Protobuf IDL](https://developers.google.com/protocol-buffers/docs/proto) converter.

References to this gem's:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems)


## DESCRIPTION:

See the [DataMeta Project](https://github.com/eBayDataMeta/DataMeta).

## FEATURES/PROBLEMS:

Protobuf support:

* ver `3.2.0` or newer

Since Protobuf supports limited subset of the DataMetaDOM features, DataMeta's features that are not supported by
Protobuf cause an error during export.

## SYNOPSIS:

### Protobuf IDL generator

Since DataMeta DOM is superset of Protobuf data types, tradeoffs are made:


* Runnables:
  * `dataMetaProtobufGen.rb` - generate [Protobuf IDL](https://developers.google.com/protocol-buffers/docs/proto)

Usage:

    dataMetaProtobufGen.rb <DataMeta DOM source file name>

It will output your Protobuf IDL to STDOUT and write the log file named `dataMetaProtobuf.log` in which you may find
some useful information about what just happened. This log is written into the current directory.

DataMeta type conversions:

* `datetime` - Protobuf 3 does have a type named `Timestamp`, but it's new and flakey, therefore we export `datetime` as
    the Protobuf IDL `string` type.
* Any DataMeta aggregate type except `mapping`: all of `list`, `deque`, `set` are exported as Protobuf's `repeated`.    
* Since Protobuf has dropped support for the "required" vs "optional", we use `repeatable` for the optional fields.
* Protobuf makes maps non-repeatable, therefore maps must be required in DataMetaDOM.
* DataMeta DOM's `mapping` translates to Protobuf's `map`. Since Protobuf does not support mapping values, 
    therefore DataMeta DOM's `mapping` values are dropped.

## REQUIREMENTS:

* No special requirements

## INSTALL:

    gem install dataMetaProtobuf

## LICENSE:

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)
