include jq

proc t_jq1 =
  echo "test jq object"
  var jqstate = jq_init()
  var jq_int = jq_compile(jqstate, ".")
  jq_start(jqstate, jv_object(), 0)
  var jvalue = jq_next(jq_state)
  var jqk = jv_get_kind(jvalue)
  assert jqk == JV_KIND_OBJECT

proc t_jq2 =
  echo "test jq array"
  var jqstate = jq_init()
  var jq_int = jq_compile(jqstate, "keys")
  var input = jv_parse("{}")
  jq_start(jqstate, input, 0)
  var jvalue = jq_next(jq_state)
  var jqk = jv_get_kind(jvalue)
  assert jqk == JV_KIND_ARRAY

t_jq1()
t_jq2()
