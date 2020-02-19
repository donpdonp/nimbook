type
  JqBidAsk* = object
    bids*: string
    asks*: string

  JqUrl* = object
    url*: string
    jq*: string

  Source* = ref object
    name* : string
    url* : string
    jq*  : JqBidAsk
    market_list*: JqUrl
    taker_fee*: float
    maker_fee*: float
