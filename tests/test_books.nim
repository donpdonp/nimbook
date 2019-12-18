import unittest
import types

suite "books":
  setup:
    var books = Books(askbid: AskBid.ask, books: @[])
    let price = 1.0
    let ticker = Ticker(symbol: "TKR1")


  test "test_books_offers_better_than":
    var winning = books.offers_better_than(price, ticker)
    doAssert(winning.books.len() == 0)


