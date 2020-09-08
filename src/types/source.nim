
type
  JqBidAsk* = object
    bids*: string
    asks*: string

  JqUrl* = object
    urls*: seq[string]
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
    trade_gas*: float
    deposit_gas*: float
    withdrawal_gas*: float