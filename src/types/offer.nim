import strutils

type
  Offer* = object
    base_qty*: float
    quote_qty*: float
    time*: string

proc `$`*(o: Offer): string =
  o.base_qty.formatFloat(ffDecimal, 6) & "@" & o.quote_qty.formatFloat(ffDecimal, 6)

proc `quote$`*(o: Offer): string =
  o.quote_qty.formatFloat(ffDecimal, 6)

proc quote*(o: Offer, flipped: bool): float =
  if flipped:
    1/o.quote_qty
  else:
    o.quote_qty
