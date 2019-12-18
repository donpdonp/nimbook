import unittest
import types

suite "Offer":
  setup:
    var o = Offer(base_qty:1, quote:2)

  test "offer":
    check(o.quote_side(TickerSide.Quote).quote == o.quote)

  test "offer_price_invert":
    check(o.quote_side(TickerSide.Base).quote == 1/o.quote)

  test "offer_swap":
    var s = o.swap()
    check(s.quote == 1/o.quote)
    check(s.base_qty == o.base_qty * o.quote)
