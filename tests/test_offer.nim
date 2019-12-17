import types

proc test_offer =
  var o = Offer(base_qty:1, quote:2)
  doAssert(o.quote_side(TickerSide.Quote).quote == o.quote)

proc test_offer_price_invert =
  var o = Offer(base_qty:1, quote:2)
  doAssert(o.quote_side(TickerSide.Base).quote == 1/o.quote)

proc test_offer_swap =
  var o = Offer(base_qty:1, quote:2)
  var s = o.swap()
  doAssert(s.quote == 1/o.quote)
  doAssert(s.base_qty == o.base_qty * o.quote)

test_offer()
test_offer_price_invert()
test_offer_swap()
