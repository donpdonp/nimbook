# nim
import httpClient, strutils, strformat, base64
# nimble
import libjq, jqutil
# local
import types

var client = newHttpClient(timeout=800)

proc marketlistload*(jqurl: JqUrl, source: Source): seq[Market] =
  echo "marketlistload ", jqurl.url
  var markets: seq[Market]
  client.headers = newHttpHeaders({ "User-Agent": "curl/7.58.0",
                                    "Accept": "*/*" })
  var json:string = client.getContent(jqurl.url)
  var jq_state = libjq.jq_init()
  var compile_success = libjq.jq_compile(jq_state, jqurl.jq)
  if compile_success == 1:
    var jdata = libjq.jv_parse(json)
    libjq.jq_start(jq_state, jdata, 0)
    var jqmarkets = libjq.jq_next(jq_state)
    jqutil.jqArrayAddSeqMarket(markets, jqmarkets, source)
    libjq.jv_free(jqmarkets)
    libjq.jq_teardown(addr jq_state)
  else:
    echo "marketlistload jq compile fail ", jqurl.jq
  markets

proc marketbooksload*(market: Market): (seq[Offer], seq[Offer]) =
  var url = market.source.url.replace("%base%", market.base.symbol).replace("%quote%", market.quote.symbol)
  let json:string = client.getContent(url)

  var bids:seq[Offer]
  let jq_bids = jqutil.jqrun(json, market.source.jq.bids)
  var bid_floats = jqutil.jqArrayToSeqFloat(jq_bids)
  libjq.jv_free(jq_bids)
  for bfloat in bid_floats:
    bids.add(Offer(base_qty: bfloat[0], quote: bfloat[1]))

  var asks:seq[Offer]
  let jq_asks = jqutil.jqrun(json, market.source.jq.asks)
  var ask_floats = jqutil.jqArrayToSeqFloat(jq_asks)
  libjq.jv_free(jq_asks)
  for afloat in ask_floats:
    asks.add(Offer(base_qty: afloat[0], quote: afloat[1]))
  (asks, bids)

proc influxpush*(url: string, username: string, password: string,
  ticker_pair: (Ticker, Ticker), cost: float, profit: float) =
  let pair = &"{ticker_pair[0]}-{ticker_pair[1]}"
  let body = &"arb,pair={pair} profit={profit},cost={cost}"
  echo body
  client.headers["Authorization"] = "Basic " & base64.encode(username & ":" & password)
  let response = client.request(url, httpMethod = HttpPost, body = $body)
  echo &"{response.status} {response.body}"

