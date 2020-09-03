#nim
#local
import net, jqutil, libjq

proc gas*(): int64 =
  var url = "https://ethgasstation.info/api/ethgasAPI.json"
  var json = net.getContent(url)
  var jq_script = ".fast"
  var gas_fast_value = jqutil.jqrun(json, jq_script)
  if libjq.jv_is_valid(gas_fast_value) == 1:
    var gas_fast_wei = toInt(libjq.jv_number_value(gas_fast_value)) * 100000000
    return gas_fast_wei
  else:
    var jerr = libjq.jv_invalid_get_msg(gas_fast_value)
    var err = libjq.jv_string_value(jerr)
    echo "eth.gas jq failed on {jq_script}", err
    echo json
