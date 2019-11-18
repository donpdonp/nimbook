type
  Market* = object
    source*: string
    base*: string
    quote*: string
    bqbook*: seq[Offer]
    qbbook*: seq[Offer]

proc MarketFromJq(source: string, base: string, quote: string): Market =
  Market(source: source, base: base, quote: quote)