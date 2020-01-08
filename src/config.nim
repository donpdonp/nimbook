# nim
import yaml/serialization, yaml/presenter, streams, tables, sequtils, strformat
# nimble
import redis
# local
import types

type
  Config* = object
    settings*: Settings
    sources*: seq[Source]
  Settings* = object
    redis: string

var redis_client: redis.Redis

proc load*(filename: string): Config =
  var config: Config

  var stream1 = newFileStream(filename)
  serialization.load(stream1, config.settings)
  stream1.close()
  echo config.settings

  var stream2 = newFileStream("sources.yaml")
  serialization.load(stream2, config.sources)
  stream2.close()

  redis_client = redis.open()
  let keys = redis_client.keys("*")
  echo fmt("redis keys {keys.len}")
  config

proc marketload*(config: Config): Table[(string, string), seq[Market]] =
  var mt: Table[(string, string), seq[Market]]
  var stream = newFileStream("all_markets.yaml")
  load(stream, mt)
  stream.close()
  mt

proc marketsave*(config: Config, mt: Table[(string, string), seq[Market]]) =
  var stream = newFileStream("all_markets.yaml", fmWrite)
  dump(mt, stream)
  stream.close()
  var vals = filter(toSeq(mt.values()), proc(ms: seq[Market]): bool = len(ms) > 1 )
  var jstream = newFileStream("all_markets.json", fmWrite)
  dump(vals, jstream, options = defineOptions(style = psJson))
  jstream.close()

proc bookssave*(books: Books, filename: string) =
  var stream = newFileStream(filename, fmWrite)
  dump(books, stream)
  stream.close()

proc booksload*(filename: string): Books =
  var books: Books
  var stream = newFileStream(filename)
  load(stream, books)
  stream.close()
  books
