type
  Offer* = object
    base_qty*: float
    quote_qty*: float
    time*: string

proc quote*(o: Offer, flipped: bool): float =
  if flipped:
    1/o.quote_qty
  else:
    o.quote_qty
