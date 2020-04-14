# nim
import yaml/serialization, yaml/presenter, streams, tables, os, sequtils
# nimble
import redis, ulid
# local
import types, net

type
  Config* = object
    settings*: Settings
    sources*: seq[Source]
  Settings* = object
    redis: string
    influx: Influx
    delay*: float
    profit_minimum*: float
    ratio_minimum*: float
  Influx = object
    url: string
    username: string
    password: string

type MarketMatches* = Table[(string, string), seq[Market]]

var redis_client: redis.Redis

proc load*(filename: string): Config =
  var config: Config

  var stream1 = newFileStream(filename)
  serialization.load(stream1, config.settings)
  stream1.close()

  var stream2 = newFileStream("exchanges.yaml")
  serialization.load(stream2, config.sources)
  stream2.close()

  redis_client = redis.open()
  config

proc marketload*(config: Config): MarketMatches =
  var mt: Table[(string, string), seq[Market]]
  var stream = newFileStream("all_markets.yaml")
  load(stream, mt)
  stream.close()
  mt

proc marketsave*(config: Config, mt: Table[(string, string), seq[Market]]) =
  var stream = newFileStream("all_markets.yaml", fmWrite)
  dump(mt, stream)
  stream.close()
  # var vals = filter(toSeq(mt.values()), proc(ms: seq[Market]): bool = len(ms) > 1)
  # var jstream = newFileStream("all_markets.json", fmWrite)
  # dump(vals, jstream, options = defineOptions(style = psJson))
  # jstream.close()

proc activeSources*(config: Config): seq[Source] =
  config.sources.filter(proc (s: Source): bool = s.active)

proc bookssave*(books: Books, filename: string) =
  var stream = newFileStream(filename, fmWrite)
  dump(books, stream)
  stream.close()

proc jsonsave*(arb_id: string, market_name: string, json: string) =
  let arbs_root = "arbs"
  createDir(arbs_root)
  let arb_dir = "." & "/" & arbs_root & "/" & arb_id
  createDir(arb_dir)
  let market_file = arb_dir & "/" & market_name
  writeFile(market_file, json)

proc redisPush(arb_report: ArbReport) =
  # file
  let arbs_root = "arbs"
  let arb_dir = "." & "/" & arbs_root & "/" & arb_report.id
  let arb_filename = arb_dir & "/order"
  var stream = newFileStream(arb_filename, fmWrite)
  serialization.dump(arb_report, stream, options = defineOptions(
      style = psJson))
  stream.close()
  # redis
  let payload = serialization.dump(arb_report, options = defineOptions(
      style = psJson))
  let rkey = "arb:" & arb_report.id
  let rx = redis_client.hset(rkey, "json", payload)
  let rx2 = redis_client.lpush("orders", arb_report.id)
  let rx3 = redis_client.publish("orders", arb_report.id)

proc arb_id_gen*(): string =
  ulid()

proc arbPush*(config: Config, report: ArbReport) =
  redisPush(report)
  if config.settings.influx.url.len > 0:
    net.influxpush(config.settings.influx.url, config.settings.influx.username,
      config.settings.influx.password, report)
