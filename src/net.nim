# nim
import httpClient
# nimble
import libjq
# local
import types

var client = newHttpClient(timeout=800)

# libjq - jv_copy() [increment refcount] before every non-final use

proc jqArrayToSeqFloat(jqarray: libjq.jq_Value): seq[seq[float]] =
  var array: seq[seq[float]]
  for idx in 0..libjq.jv_array_length(libjq.jv_copy(jqarray))-1:
    var element = libjq.jv_array_get(libjq.jv_copy(jqarray), idx)
    if libjq.jv_get_kind(libjq.jv_copy(element)) == libjq.JV_KIND_ARRAY:
      var twofloats: seq[float]
      var firstfloat = libjq.jv_array_get(libjq.jv_copy(element), 0)
      twofloats.add(libjq.jv_number_value(firstfloat))
      var secondfloat = libjq.jv_array_get(libjq.jv_copy(element), 1)
      twofloats.add(libjq.jv_number_value(secondfloat))
      array.add(twofloats)
  array

proc jqArrayAddSeqMarket(markets: var seq[Market], jqarray: libjq.jq_Value, source: Source) =
  for idx in 0..libjq.jv_array_length(libjq.jv_copy(jqarray))-1:
    var element = libjq.jv_array_get(libjq.jv_copy(jqarray), idx)
    var nim_elements = Market(source: source,
      base: $libjq.jv_string_value(libjq.jv_array_get(libjq.jv_copy(element), 0)),
      quote: $libjq.jv_string_value(libjq.jv_array_get(libjq.jv_copy(element), 1)))
    markets.add(nim_elements)

proc jqrun(json: string, jq_code: string): libjq.jq_Value =
  var jq_state = libjq.jq_init()
  var compile_success = libjq.jq_compile(jq_state, jq_code)
  if compile_success == 1:
    var jdata = libjq.jv_parse(json)
    libjq.jq_start(jq_state, jdata, 0)
    var jq_result = libjq.jq_next(jq_state)
    libjq.jq_teardown(addr jq_state)
    return jq_result

#proc jqfor(array: libjq.jq_Value, p: proc()...

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
    jqArrayAddSeqMarket(markets, jqmarkets, source)
    libjq.jv_free(jqmarkets)
    libjq.jq_teardown(addr jq_state)
  else:
    echo "marketlistload jq compile fail ", jqurl.jq
  markets

proc marketbooksload*(source: Source, url: string): (seq[Offer], seq[Offer]) =
  echo "marketbooksload ", url
  let json:string = client.getContent(url)

  var bids:seq[Offer]
  let jq_bids = jqrun(json, source.jq.bids)
  var bid_floats = jqArrayToSeqFloat(jq_bids)
  libjq.jv_free(jq_bids)
  for bfloat in bid_floats:
    bids.add(Offer(base_qty: bfloat[0], quote_qty: bfloat[1]))

  var asks:seq[Offer]
  let jq_asks = jqrun(json, source.jq.asks)
  var ask_floats = jqArrayToSeqFloat(jq_asks)
  libjq.jv_free(jq_asks)
  for afloat in ask_floats:
    asks.add(Offer(base_qty: afloat[0], quote_qty: afloat[1]))
  (asks, bids)
