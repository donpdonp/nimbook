# nim
# nimble
import libjq
# local
import types

# libjq - jv_copy() [increment refcount] before every non-final use

proc jqArrayToSeqFloat*(jqarray: libjq.jq_Value): seq[seq[float]] =
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

proc jqArrayAddSeqMarket*(markets: var seq[Market], jqarray: libjq.jq_Value, source: Source) =
  for idx in 0..libjq.jv_array_length(libjq.jv_copy(jqarray))-1:
    var element = libjq.jv_array_get(libjq.jv_copy(jqarray), idx)
    var base_symbol = $libjq.jv_string_value(libjq.jv_array_get(libjq.jv_copy(element), 0))
    var quote_symbol = $libjq.jv_string_value(libjq.jv_array_get(libjq.jv_copy(element), 1))
    var nim_elements = Market(source: source,
      base: Ticker(symbol: base_symbol),
      quote: Ticker(symbol: quote_symbol))
    markets.add(nim_elements)

proc jqrun*(json: string, jq_code: string): libjq.jq_Value =
  var jq_state = libjq.jq_init()
  var compile_success = libjq.jq_compile(jq_state, jq_code)
  if compile_success == 1:
    var jdata = libjq.jv_parse(json)
    libjq.jq_start(jq_state, jdata, 0)
    var jq_result = libjq.jq_next(jq_state)
    libjq.jq_teardown(addr jq_state)
    return jq_result

#proc jqfor(array: libjq.jq_Value, p: proc()...
