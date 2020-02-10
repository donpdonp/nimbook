# nim
import httpClient, strutils, strformat, base64
# nimble
import libjq, jqutil
# local
import types


proc getContent*(url: string): string =
  var Client = newHttpClient(timeout = 800)
  Client.getContent(url)

proc jq_obj_get_number(value: libjq.jq_value, key: string): cdouble =
  let jqv = libjq.jv_object_get(libjq.jv_copy(value), libjq.jv_string(key))
  libjq.jv_number_value(jqv)

proc jq_obj_get_string(value: libjq.jq_value, key: string): string =
  var nimstr = ""
  let jqv = libjq.jv_object_get(libjq.jv_copy(value), libjq.jv_string(key))
  nimstr.add(libjq.jv_string_value(jqv))
  nimstr

proc market_format*(source: Source, value: libjq.jq_value): Market =
      var newMarket = Market(source: source, swapped: false,
          base: Ticker(symbol: jq_obj_get_string(value, "base")),
          priceDecimals: jq_obj_get_number(value, "price_decimals"),
          quote: Ticker(symbol: jq_obj_get_string(value, "quote")),
          quantityDecimals: jq_obj_get_number(value, "quantity_decimals"),
      )
      newMarket

proc marketlistload*(jqurl: JqUrl, source: Source): seq[Market] =
  echo "marketlistload ", jqurl.url
  var markets: seq[Market]
  var Client = newHttpClient(timeout = 800)
  Client.headers = newHttpHeaders({"User-Agent": "curl/7.58.0",
                                    "Accept": "*/*"})
  var json: string = Client.getContent(jqurl.url)
  var jq_state = libjq.jq_init()
  var compile_success = libjq.jq_compile(jq_state, jqurl.jq)
  if compile_success == 1:
    var jdata = libjq.jv_parse(json)
    libjq.jq_start(jq_state, jdata, 0)
    var jqmarkets = libjq.jq_next(jq_state)
    for idx in 0..jqutil.jqArrayLen(jqmarkets)-1:
      let jqmarket = libjq.jv_array_get(libjq.jv_copy(jqmarkets), idx)
      let new_market = market_format(source, jqmarket)
      markets.add(new_market)
    libjq.jv_free(jqmarkets)
    libjq.jq_teardown(addr jq_state)
  else:
    echo "marketlistload jq compile fail ", jqurl.jq
  markets

    
proc marketoffers_format*(json: string, market: Market): (seq[Offer], seq[Offer]) =
  var bids: seq[Offer]
  let jq_bids = jqutil.jqrun(json, market.source.jq.bids)
  var bid_floats = jqutil.jqArrayToSeqFloat(jq_bids)
  libjq.jv_free(jq_bids)
  for bfloat in bid_floats:
    bids.add(Offer(base_qty: bfloat[0], quote: bfloat[1]))

  var asks: seq[Offer]
  let jq_asks = jqutil.jqrun(json, market.source.jq.asks)
  var ask_floats = jqutil.jqArrayToSeqFloat(jq_asks)
  libjq.jv_free(jq_asks)
  for afloat in ask_floats:
    asks.add(Offer(base_qty: afloat[0], quote: afloat[1]))
  (asks, bids)

proc influxpush*(url: string, username: string, password: string,
  ticker_pair: (Ticker, Ticker), cost: float, profit: float, avg_price: float) =
  let pair = &"{ticker_pair[0]}-{ticker_pair[1]}"
  let body = &"arb,pair={pair} profit={profit},cost={cost},avg_price={avg_price}"
  echo &"influx: {body}"
  var Client = newHttpClient(timeout = 800)
  Client.headers["Authorization"] = "Basic " & base64.encode(username & ":" & password)
  let response = Client.request(url, httpMethod = HttpPost, body = $body)
  let status = response.status.split(" ")[0].parseInt
  if status < 200 or status >= 300:
    echo &"{response.status} {response.body}"
