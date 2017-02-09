# dataMetaParse

DataMeta Parser commons: common rules and some reusable grammars

References to this gem's:

* [Source](https://github.com/eBayDataMeta/DataMeta-gems)

## DESCRIPTION:

See the [DataMeta Project](https://github.com/eBayDataMeta/DataMeta)

## FEATURES/PROBLEMS:

* This gem uses [treetop](http://treetop.rubyforge.org) for grammar processing which only works with
[PEGs](http://en.wikipedia.org/wiki/Parsing_expression_grammar), same as [Antlr](http://www.antlr.org) and many other
popular grammar processors. Hence, be careful with features that
[PEGs](http://en.wikipedia.org/wiki/Parsing_expression_grammar) do not support,
like [left recursion](http://en.wikipedia.org/wiki/Left_recursion).

### DataMeta URI parsing

This gem provides convenient class for URI parsing with DataMeta Specifics.

The URI format is [typical](http://support.microsoft.com/kb/135975 "URL Format - MS Knowledge Base"):

    protocol://user:password@server:port/path?query

Out of which,

* `protocol`: required, corresponds with DataMeta "platform", can be:
    * `oracle` - for Oracle connections
    * `mysql` - for MySQL connections
* `user`: optional, the user name for authentication
* `password`: password for the user, can be only used in conjunction with the `user`. Depending on a protocol,
    can be either required or optional.
* `server`: required, host name or IP address
* `port`: optional, port number to connect to
* `path`: optional, protocol specific, may refer either to a full path on the server's filesystem or a name of the database
* `?query`: optional, regular format for the URL query, in `key=value` format separated by <tt>&</tt>, any special
    characters encoded in the <tt>%xx</tt> format.

## SYNOPSIS:

* No command line runnables in this gem, it is a library only.

## INSTALL:

    gem install dataMetaParse

## LICENSE:

[Apache v 2.0](https://github.com/eBayDataMeta/DataMeta/blob/master/LICENSE.md)
