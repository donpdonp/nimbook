# nim
import yaml/serialization, yaml/presenter, streams, tables, sequtils, strformat
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
  Influx = object
    url: string
    username: string
    password: string

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
  var vals = filter(toSeq(mt.values()), proc(ms: seq[Market]): bool = len(ms) > 1)
  var jstream = newFileStream("all_markets.json", fmWrite)
  dump(vals, jstream, options = defineOptions(style = psJson))
  jstream.close()

proc bookssave*(books: Books, filename: string) =
  var stream = newFileStream(filename, fmWrite)
  dump(books, stream)
  stream.close()

type ArbReport = object
  id: string
  buysell: string
  base_ticker: string
  quote_ticker: string
  market_name: string
  market_base: string
  market_quote: string
  limit: float
  cost: float
  profit: float

proc bookpub(aid: string, ticker_pair: (Ticker, Ticker), books: Books,
    best: float, cost: float, profit: float) =
  for book in books.books:
    let arb_report = ArbReport(id: aid,
                          buysell: if books.askbid ==
                          AskBid.ask: "buy" else: "sell",
                          base_ticker: ticker_pair[0].symbol,
                          quote_ticker: ticker_pair[0].symbol,
                          market_name: book.market.source.name,
                          market_base: book.market.base.symbol,
                          market_quote: book.market.quote.symbol,
                          limit: best,
                          cost: cost, profit: profit)
    let payload = serialization.dump(arb_report, options = defineOptions(
        style = psJson))
    let rx = redis_client.lpush("orders", payload)
    let rx2 = redis_client.publish("orders", arb_report.id)

proc arbpub*(config: Config, ticker_pair: (Ticker, Ticker), askbooks: Books,
    bestask: float, bidbooks: Books, bestbid: float, cost: float,
    profit: float) =
  let aid = ulid()
  bookpub(aid, ticker_pair, askbooks, bestask, cost, profit)
  bookpub(aid, ticker_pair, bidbooks, bestbid, cost, profit)
  if config.settings.influx.url.len > 0:
    net.influxpush(config.settings.influx.url, config.settings.influx.username,
      config.settings.influx.password,
      ticker_pair, cost, profit)
