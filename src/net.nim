# nim
import httpClient, strutils, strformat, base64, asyncdispatch
# nimble
import libjq, jqutil, ws
# local
import types


proc getContent*(url: string): string =
  var Client = newHttpClient(timeout = 800)
  Client.getContent(url)

proc wsListen*(url: string) {.async, gcsafe.} =
  echo url
  var ws = await newWebSocket(url)
  echo await ws.receiveStrPacket()
  await ws.send("{}")
  echo await ws.receiveStrPacket()
  ws.close()

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
      price_decimals: jq_obj_get_number(value, "price_decimals"),
      quote: Ticker(symbol: jq_obj_get_string(value, "quote")),
      quantity_decimals: jq_obj_get_number(value, "quantity_decimals"),
      min_order_size: jq_obj_get_string(value, "min_order_size"),
      base_contract: jq_obj_get_string(value, "base_contract"),
      quote_contract: jq_obj_get_string(value, "quote_contract"),
  )
  newMarket

proc marketlistload*(source: Source): seq[Market] =
  var markets: seq[Market]
  var Client = newHttpClient(timeout = 800)
  Client.headers = newHttpHeaders({"User-Agent": "curl/7.58.0",
                                    "Accept": "*/*"})
  var jsonparts: seq[string]
  for list_url in source.market_list.urls:
    echo list_url
    jsonparts.add(Client.getContent(list_url))
  var jqmarkets = jqutil.jqrun(jsonparts, source.market_list.jq)
  if libjq.jv_is_valid(jqmarkets) == 1:
    for idx in 0..jqutil.jqArrayLen(jqmarkets)-1:
      let jqmarket = libjq.jv_array_get(libjq.jv_copy(jqmarkets), idx)
      let new_market = market_format(source, jqmarket)
      markets.add(new_market)
    libjq.jv_free(jqmarkets)
  else:
    var jerr = libjq.jv_invalid_get_msg(jqmarkets)
    var err = libjq.jv_string_value(jerr)
    echo "marketlistload jq compile fail ", err
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

proc influxline*(books: Books, book: Book, offer: Offer): string =
  &"offer,side={books.askbid},exchange={book.market.source.name},base_token={book.market.base.symbol},quote_token={book.market.quote.symbol} base={offer.base_qty:0.8f},quote={offer.quote:0.8f}"

proc influxpush*(url: string, username: string, password: string,
                 ticker_pair: (Ticker, Ticker), cost: float, profit: float,
                 ratio: float, avg_price: float,
                 ask_orders: Books, bid_orders: Books) =
  var datalines: seq[string] = @[]
  let pair = &"{ticker_pair[0]}-{ticker_pair[1]}"
  datalines.add(&"arb,pair={pair},base_token={ticker_pair[0]},quote_token={ticker_pair[1]} profit={profit:0.5f},cost={cost:0.5f},ratio={ratio:0.5f},avg_price={avg_price:0.5f}")
  for book in ask_orders.books:
    for offer in book.offers:
      datalines.add(influxline(ask_orders, book, offer))
  for book in bid_orders.books:
    for offer in book.offers:
      datalines.add(influxline(bid_orders, book, offer))
  for line in datalines:
    echo &"influx: {line}"
  let body = datalines.join("\n")
  var Client = newHttpClient(timeout = 800)
  Client.headers["Authorization"] = "Basic " & base64.encode(username & ":" & password)
  let response = Client.request(url, httpMethod = HttpPost, body = $body)
  let status = response.status.split(" ")[0].parseInt
  if status < 200 or status >= 300:
    echo &"{response.status} {response.body}"

