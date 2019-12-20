import unittest
import types

suite "Trade":
  setup:
    var ask_books = Books(askbid: AskBid.ask, books: @[])

  test "one opp":
    check(true)
