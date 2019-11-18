type
  AskBid* = enum ask, bid

  Market* = object
    source_name*: string
    base*: string
    quote*: string
    bqbook*: seq[Offer]
    qbbook*: seq[Offer]

proc MarketFromJq(source_name: string, base: string, quote: string): Market =
  Market(source_name: source_name, base: base, quote: quote)