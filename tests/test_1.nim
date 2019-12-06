import tables
import types, nimbook, config

proc quick_market(source_name: string, symbol_base: string, symbol_quote: string): Market =
  var source = Source(name: source_name)
  var market = Market(source: source, base: Ticker(symbol: symbol_base), quote: Ticker(symbol: symbol_quote))
  market

proc setup_empty(): (Books, Books) =
  var marketA = quick_market("TestExchA", "TKR1", "TKR2")
  var bookA = Book(market: marketA)
  bookA.offers.add(@[Offer(base_qty: 1, quote_qty: 2)])

  var marketB = quick_market("TestExchB", "TKR1", "TKR2")
  var bookB = Book(market: marketB)
  bookB.offers.add(@[Offer(base_qty: 1, quote_qty: 1.1)])

  var asks = Books(askbid: AskBid.ask, books: @[bookA])
  var bids = Books(askbid: AskBid.bid, books: @[bookB])
  (asks,bids)

proc setup_cross(): (Books, Books) =
  var marketA = quick_market("TestExchA", "TKR1", "TKR2")
  var bookA = Book(market: marketA)
  bookA.offers.add(@[Offer(base_qty: 1, quote_qty: 1.3)])

  var marketB = quick_market("TestExchB", "TKR1", "TKR2")
  var bookB = Book(market: marketB)
  bookB.offers.add(@[Offer(base_qty: 1, quote_qty: 1.4)])

  var asks = Books(askbid: AskBid.ask, books: @[bookA])
  var bids = Books(askbid: AskBid.bid, books: @[bookB])
  (asks,bids)

proc t_11 =
  var markets: seq[Market]
  markets.add(quick_market("TestExchA", "TKR1", "TKR2"))
  markets.add(quick_market("TestExchB", "TKR1", "TKR2"))
  var matches:Table[(string, string), seq[Market]] = markets_match(markets)
  doAssert 1 == len(matches)

proc t_1 =
  var (asks,bids) = setup_empty()
  var (askwins, bidwins) = nimbook.overlap(("TKR1", "TKR2"), asks, bids)
  doAssert 0 == len(askwins.books)
  doAssert 0 == len(bidwins.books)

proc t_2 =
  var (asks,bids) = setup_cross()
  var (askwins, bidwins) = overlap(("TKR1", "TKR2"), asks, bids)
  assert 1 == len(askwins.books)
  assert 1 == len(bidwins.books)

proc t_3 =
  var (asks,bids) = setup_cross()
  var (askwins, bidwins) = overlap(("TKR1", "TKR2"), asks, bids)
  trade(askwins, bidwins)

t_11()
t_1()
t_2()
t_3()
