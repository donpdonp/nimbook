type
  JqBidAsk* = object
    bids*: string
    asks*: string

  JqUrl* = object
    url*: string
    jq*: string

  Source* = ref object
    name*: string
    active*: bool
    url*: string
    jq*: JqBidAsk
    ws_url*: string
    market_list*: JqUrl
    taker_fee*: float
    maker_fee*: float
