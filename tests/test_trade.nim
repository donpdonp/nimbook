import unittest
import types, nimbook, config

suite "Trade Empty":
  setup:
    var ask_books = Books(askbid: AskBid.ask, books: @[])
    var bid_books = Books(askbid: AskBid.bid, books: @[])

  test "trade":
    ask_books.books.add(Book())
    let (ask_orders, bid_orders) = trade(ask_books, bid_books)
    check(ask_orders.base_total == 0)

suite "Trade equal supply":
  setup:
    let source = Source(name: "SkamMarket")
    let market = Market(source: source, base: Ticker(symbol:"A"), quote: Ticker(symbol:"B"))
    let aoffer = Offer(base_qty: 1, quote: 1)
    var abook = Book(market: market, offers: @[aoffer])
    var ask_books = Books(askbid: AskBid.ask, books: @[abook])
    let boffer = Offer(base_qty: 1, quote: 1.1)
    var bbook = Book(market: market, offers: @[boffer])
    var bid_books = Books(askbid: AskBid.bid, books: @[bbook])

  test "trade":
    ask_books.books.add(Book())
    let (ask_orders, bid_orders) = trade(ask_books, bid_books)
    check(ask_orders.base_total == 1)

suite "Trade excess ask":
  setup:
    let source = Source(name: "SkamMarket")
    let market = Market(source: source, base: Ticker(symbol:"A"), quote: Ticker(symbol:"B"))
    let aoffer = Offer(base_qty: 2, quote: 1)
    var abook = Book(market: market, offers: @[aoffer])
    var ask_books = Books(askbid: AskBid.ask, books: @[abook])
    let boffer = Offer(base_qty: 1, quote: 1.1)
    var bbook = Book(market: market, offers: @[boffer])
    var bid_books = Books(askbid: AskBid.bid, books: @[bbook])

  test "trade":
    ask_books.books.add(Book())
    let (ask_orders, bid_orders) = trade(ask_books, bid_books)
    check(ask_orders.base_total == 1)

suite "Trade excess bid":
  setup:
    let source = Source(name: "SkamMarket")
    let market = Market(source: source, base: Ticker(symbol:"A"), quote: Ticker(symbol:"B"))
    let aoffer = Offer(base_qty: 1, quote: 1)
    var abook = Book(market: market, offers: @[aoffer])
    var ask_books = Books(askbid: AskBid.ask, books: @[abook])
    let boffer = Offer(base_qty: 2, quote: 1.1)
    var bbook = Book(market: market, offers: @[boffer])
    var bid_books = Books(askbid: AskBid.bid, books: @[bbook])

  test "trade":
    let (ask_orders, bid_orders) = trade(ask_books, bid_books)
    check(ask_orders.base_total == 1)

suite "Trade cache":
  setup:
    let ask_books = config.booksload("data/ask_wins")
    let bid_books = config.booksload("data/bid_wins")

  test "cache":
    let profit = trade(ask_books, bid_books)
    check(profit == 1)
