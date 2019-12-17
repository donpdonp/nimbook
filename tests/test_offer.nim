import types

proc test_offer =
  var o = Offer(base_qty:1, quote_qty:2)
  doAssert(o.quote(TickerSide.Quote) == o.quote_qty)

proc test_offer_invert =
  var o = Offer(base_qty:1, quote_qty:2)
  doAssert(o.quote(TickerSide.Base) == 1/o.quote_qty)

test_offer()
test_offer_invert()
