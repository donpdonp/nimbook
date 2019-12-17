import tables
import types, nimbook, config

proc quick_market(source_name: string, symbol_base: string, symbol_quote: string): Market =
  var source = Source(name: source_name)
  var market = Market(source: source, base: Ticker(symbol: symbol_base), quote: Ticker(symbol: symbol_quote))
  market

proc setup_empty(): (Books, Books) =
  var marketA = quick_market("TestExchA", "TKR1", "TKR2")
  var bookA = Book(market: marketA)
  bookA.offers.add(@[Offer(base_qty: 1, quote: 2)])

  var marketB = quick_market("TestExchB", "TKR1", "TKR2")
  var bookB = Book(market: marketB)
  bookB.offers.add(@[Offer(base_qty: 1, quote: 1.1)])

  var asks = Books(askbid: AskBid.ask, books: @[bookA])
  var bids = Books(askbid: AskBid.bid, books: @[bookB])
  (asks,bids)

proc setup_cross(): (Books, Books) =
  var marketA = quick_market("TestExchA", "TKR1", "TKR2")
  var bookA = Book(market: marketA)
  bookA.offers.add(@[Offer(base_qty: 1, quote: 1.3)])

  var marketB = quick_market("TestExchB", "TKR1", "TKR2")
  var bookB = Book(market: marketB)
  bookB.offers.add(@[Offer(base_qty: 2.01, quote: 1.4)])

  var asks = Books(askbid: AskBid.ask, books: @[bookA])
  var bids = Books(askbid: AskBid.bid, books: @[bookB])
  (asks,bids)

proc t_11 =
  var markets: seq[Market]
  markets.add(quick_market("TestExchA", "TKR1", "TKR2"))
  markets.add(quick_market("TestExchB", "TKR1", "TKR2"))
  var matches:Table[(string, string), seq[Market]] = marketpairs_match(markets)
  doAssert 1 == len(matches)

proc t_1 =
  var (asks,bids) = setup_empty()
  let pair = (Ticker(symbol:"TKR1"), Ticker(symbol:"TKR2"))
  var (askwins, bidwins) = nimbook.overlap(pair, asks, bids)
  doAssert 0 == len(askwins.books)
  doAssert 0 == len(bidwins.books)

proc t_2 =
  var (asks,bids) = setup_cross()
  let pair = (Ticker(symbol:"TKR1"), Ticker(symbol:"TKR2"))
  var (askwins, bidwins) = overlap(pair, asks, bids)
  assert 1 == len(askwins.books)
  assert 1 == len(bidwins.books)

proc t_3 =
  var (asks,bids) = setup_cross()
  let pair = (Ticker(symbol:"TKR1"), Ticker(symbol:"TKR2"))
  var (askwins, bidwins) = overlap(pair, asks, bids)
  trade(askwins, bidwins)

t_11()
t_1()
t_2()
t_3()
