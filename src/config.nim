# nim
import yaml/serialization, yaml/presenter, streams, tables, sequtils
# local
import types

type
  Config* = object
    sources*: seq[Source]


proc load*(filename: string): Config =
  var config: Config
  var stream = newFileStream(filename)
  serialization.load(stream, config)
  stream.close()
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
