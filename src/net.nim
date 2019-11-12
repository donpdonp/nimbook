import httpClient
import jq
import strutils, sequtils, sugar

var client = newHttpClient()

# libjq - jv_copy() [increment refcount] before every non-final use

proc jqArrayToSeqFloat(jqarray: jq_Value): seq[seq[float]] =
  var array: seq[seq[float]]
  for idx in 0..jq.jv_array_length(jq.jv_copy(jqarray))-1:
    var element = jq.jv_array_get(jq.jv_copy(jqarray), idx)
    if jq.jv_get_kind(jq.jv_copy(element)) == jq.JV_KIND_ARRAY:
      var twofloats: seq[float]
      var firstfloat = jq.jv_array_get(jq.jv_copy(element), 0)
      twofloats.add(jq.jv_number_value(firstfloat))
      var secondfloat = jq.jv_array_get(jq.jv_copy(element), 1)
      twofloats.add(jq.jv_number_value(secondfloat))
      array.add(twofloats)
  array

proc jqArrayAddSeqMarket(markets: var seq[Market], jqarray: jq_Value, source_name: string) =
  for idx in 0..jq.jv_array_length(jq.jv_copy(jqarray))-1:
    var element = jq.jv_array_get(jq.jv_copy(jqarray), idx)
    var market = Market(source: source_name,
      base: $jq.jv_string_value(jq.jv_array_get(jq.jv_copy(element), 0)),
      quote: $jq.jv_string_value(jq.jv_array_get(jq.jv_copy(element), 1)))
    markets.add(market)

proc marketlistload(jqurl: JqUrl, source_name: string): seq[Market] =
  echo "marketlistload ", jqurl.url
  var markets: seq[Market]
  var json:string = client.getContent(jqurl.url)
  var jq_state = jq.jq_init()
  var compile_success = jq.jq_compile(jq_state, jqurl.jq)
  if compile_success == 1:
    var jdata = jq.jv_parse(json)
    jq.jq_start(jq_state, jdata, 0)
    var jqmarkets = jq.jq_next(jq_state)
    jqArrayAddSeqMarket(markets, jqmarkets, source_name)
    jq.jv_free(jqmarkets)
    jq.jq_teardown(addr jq_state)
  else:
    echo "marketlistload jq compile fail ", jqurl.jq
  markets

proc sourceload(source: Source, url: string, bidask: BidAsk): seq[seq[float]] =
  echo "sourceload ", url
  var jq_state = jq.jq_init()
  var jqcode = if bidask == Bid: source.jq.bids else: source.jq.asks
  echo jqcode
  var compile_success = jq.jq_compile(jq_state, jqcode)
  if compile_success == 1:
    var json:string = client.getContent(url)
    var jdata = jq.jv_parse(json)
    jq.jq_start(jq_state, jdata, 0)
    var jqoffers = jq.jq_next(jq_state)
    var twofloats = jqArrayToSeqFloat(jqoffers)
    jq.jv_free(jqoffers)
    jq.jq_teardown(addr jq_state)
    return twofloats

