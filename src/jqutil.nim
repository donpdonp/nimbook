# nim
# nimble
import libjq
# local

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

proc jqArrayLen*(jqarray: libjq.jq_Value): cint =
  libjq.jv_array_length(libjq.jv_copy(jqarray))

proc jqArrayTupleStrings*(jqarray: libjq.jq_Value, idx: cint): (string, string) =
  var element = libjq.jv_array_get(libjq.jv_copy(jqarray), idx)
  var base_symbol = $libjq.jv_string_value(libjq.jv_array_get(libjq.jv_copy(
      element), 0))
  var quote_symbol = $libjq.jv_string_value(libjq.jv_array_get(libjq.jv_copy(
      element), 1))
  (base_symbol, quote_symbol)

proc jqrun*(jsons: seq[string], jq_code: string): libjq.jq_Value =
  var jq_state = libjq.jq_init()
  var compile_success = libjq.jq_compile(jq_state, jq_code)
  if compile_success == 1:
    var jdata: libjq.jq_Value
    if jsons.len == 1:
      jdata = libjq.jv_parse(jsons[0])
      if libjq.jv_is_valid(jdata) == 0:
        echo "jq parse early abort"
        return jdata
    else:
      jdata = libjq.jv_array()
      for json in jsons:
        var jpart = libjq.jv_parse(json)
        if libjq.jv_is_valid(jpart) == 1:
          jdata = libjq.jv_array_append(jdata, jpart)
        else:
          echo "jq parse early abort"
          return jdata
    libjq.jq_start(jq_state, jdata, 0)
    var jq_result = libjq.jq_next(jq_state)
    libjq.jq_teardown(addr jq_state)
    return jq_result

proc jqrun*(json: string, jq_code: string): libjq.jq_Value =
  jqrun(@[json], jq_code)

#proc jqfor(array: libjq.jq_Value, p: proc()...

