import yaml/serialization, streams, tables
import types

type
  Config = object
    sources: seq[Source]


proc load(filename: string): Config =
  var config: Config
  var stream = newFileStream(filename)
  load(stream, config)
  stream.close()
  config

proc marketload(): Table[(string, string), seq[Market]] =
  var mt: Table[(string, string), seq[Market]]
  var stream = newFileStream("all_markets.yaml")
  load(stream, mt)
  stream.close()
  mt

proc marketsave(mt: Table[(string, string), seq[Market]]) =
  var stream = newFileStream("all_markets.yaml", fmWrite)
  dump(mt, stream)
  stream.close()
