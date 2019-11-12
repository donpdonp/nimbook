type
  jv_Kind* = enum
    JV_KIND_INVALID, JV_KIND_NULL, JV_KIND_FALSE, JV_KIND_TRUE, JV_KIND_NUMBER,
    JV_KIND_STRING, JV_KIND_ARRAY, JV_KIND_OBJECT

type jq_State* = ptr object
type jq_Value* {.header: "<jq.h>", importc: "jv"} = object

proc jq_init*(): jq_State {.header: "<jq.h>", importc.}
proc jq_teardown*(jqs: ptr jq_State) {.header: "<jq.h>", importc.}
proc jq_start*(jsq: jq_State, jv: jq_Value, flags: cint) {.header: "<jq.h>", importc.}
proc jq_compile*(jsq: jq_State, jp: cstring): int {.header: "<jq.h>", importc.}
proc jq_next*(jsq: jq_State): jq_Value {.header: "<jq.h>", importc.}
proc jv_get_kind*(jv: jq_Value): jv_Kind {.header: "<jq.h>", importc.}
proc jv_array_length*(jv: jq_Value): cint {.header: "<jq.h>", importc.}
proc jv_array_get*(jv: jq_Value, idx: cint): jq_Value {.header: "<jq.h>", importc.}
proc jv_object*(): jq_Value {.header: "<jq.h>", importc.}
proc jv_parse*(str: cstring): jq_Value {.header: "<jq.h>", importc.}
proc jv_number_value*(jv: jq_Value): cdouble {.header: "<jq.h>", importc.}
proc jv_string_value*(jv: jq_Value): cstring {.header: "<jq.h>", importc.}
proc jv_copy*(jv: jq_Value): jq_Value {.header: "<jq.h>", importc.}
proc jv_free*(jv: jq_Value) {.header: "<jq.h>", importc.}
