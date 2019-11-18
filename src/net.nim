# nim
import httpClient, strutils, sequtils, sugar
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

proc jqArrayAddSeqMarket(markets: var seq[Market], jqarray: libjq.jq_Value, source_name: string) =
  for idx in 0..libjq.jv_array_length(libjq.jv_copy(jqarray))-1:
    var element = libjq.jv_array_get(libjq.jv_copy(jqarray), idx)
    var nim_elements = Market(source: source_name,
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

proc marketlistload*(jqurl: JqUrl, source_name: string): seq[Market] =
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
    jqArrayAddSeqMarket(markets, jqmarkets, source_name)
    libjq.jv_free(jqmarkets)
    libjq.jq_teardown(addr jq_state)
  else:
    echo "marketlistload jq compile fail ", jqurl.jq
  markets

proc marketbooksload*(source: Source, url: string): (seq[Offer], seq[Offer]) =
  echo "marketbooksload ", url
  let html:string = client.getContent(url)
  let jq_bids = jqrun(html, source.jq.bids)
  var twofloats = jqArrayToSeqFloat(jq_bids)
  libjq.jv_free(jq_bids)
  let jq_asks = jqrun(html, source.jq.asks)
  libjq.jv_free(jq_asks)
