import yaml/serialization, streams
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
