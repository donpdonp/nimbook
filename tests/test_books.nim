import unittest
import types

suite "books empty exchanges":
  setup:
    let base_ticker = Ticker(symbol: "TKR1")
    let quote_ticker = Ticker(symbol: "TKR2")

    let source1 = Source(name: "Test Exchange A")
    let market1 = Market(source: source1, base: base_ticker,
        quote: quote_ticker)
    let book1 = Book(market: market1, offers: @[])

    let source2 = Source(name: "Test Exchange B")
    let market2 = Market(source: source2, base: base_ticker,
        quote: quote_ticker)
    let book2 = Book(market: market1, offers: @[])

    var askbooks = Books(askbid: AskBid.ask, books: @[book1, book2])

  test "offers_better_than 2.0":
    let price = 1.0
    var winning = askbooks.offers_better_than(price, quote_ticker)
    check(winning.books.len() == 0)

  test "merge":
    check(book1.offers.len == 0)
    let offer1 = Offer(base_qty: 1, quote: 1)
    askbooks.merge(book1, offer1)
    check(book1.offers.len == 1)
    check(askbooks.cost == 1.0)
    askbooks.merge(book1, offer1)
    check(book1.offers.len == 1)
    check(askbooks.cost == 2.0)
    let offer2 = Offer(base_qty: 1, quote: 2)
    askbooks.merge(book1, offer2)
    check(book1.offers.len == 2)
    check(askbooks.cost == 4.0)

suite "books exchanges with arbitrage":
  setup:
    let base_ticker = Ticker(symbol: "TKR1")
    let quote_ticker = Ticker(symbol: "TKR2")

    let source1 = Source(name: "Test Exchange A")
    let market1 = Market(source: source1, base: base_ticker,
        quote: quote_ticker)
    let offer1a = Offer(base_qty: 1, quote: 1)
    let book1 = Book(market: market1, offers: @[offer1a])

    let source2 = Source(name: "Test Exchange B")
    let market2 = Market(source: source2, base: base_ticker,
        quote: quote_ticker)
    let offer2a = Offer(base_qty: 1, quote: 1)
    let book2 = Book(market: market1, offers: @[offer2a])

    var askbooks = Books(askbid: AskBid.ask, books: @[book1, book2])

  test "offers_better_than 2.0":
    let price = 2.0
    var winning = askbooks.offers_better_than(price, quote_ticker)
    check(winning.books.len() == 2)

