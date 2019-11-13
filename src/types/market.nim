type
  Market* = object
    source*: string
    base*: string
    quote*: string

  MarketNim* = (string, string, string)

proc MarketFromJq(source: string, base: string, quote: string): Market =
  Market(source: source, base: base, quote: quote)