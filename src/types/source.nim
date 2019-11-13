type
  JqBidAsk = object
    bids: string
    asks: string

  JqUrl = object
    url: string
    jq: string

  Source* = object
    name* : string
    url* : string
    jq*  : JqBidAsk
    market_list*: JqUrl

