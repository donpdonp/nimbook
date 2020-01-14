import strutils

type
  Offer* = ref object
    base_qty*: float
    quote*: float

proc `$`*(o: Offer): string =
  o.base_qty.formatFloat(ffDecimal, 6) & "@" & o.quote.formatFloat(ffDecimal, 6)

proc `quote$`*(o: Offer): string =
  o.quote.formatFloat(ffDecimal, 6)

proc swap*(o: Offer): Offer =
  Offer(base_qty: o.base_qty * o.quote, quote: 1/o.quote)

proc quote_side*(o: Offer, side: TickerSide): Offer =
  if side == TickerSide.Base:
    o.swap()
  else:
    o
