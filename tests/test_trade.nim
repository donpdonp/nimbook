import unittest
import types, nimbook

suite "Trade":
  setup:
    var ask_books = Books(askbid: AskBid.ask, books: @[])
    var bid_books = Books(askbid: AskBid.bid, books: @[])

  test "one opp":
    ask_books.books.add(Book())
    trade(ask_books, bid_books)
    check(true)
