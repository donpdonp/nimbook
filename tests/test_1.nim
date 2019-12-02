import types
include nimbook, config

proc setup_empty(): (Books, Books) =
  var sourceA = Source(name:"Exchange A")
  var marketA = Market(source: sourceA, base: "TKR1", quote: "TKR2")
  var offersA = @[Offer(base_qty: 1, quote_qty: 2)]
  var bookA = Book(market: marketA, offers: offersA)

  var sourceB = Source(name:"Exchange B")
  var marketB = Market(source: sourceB, base: "TKR1", quote: "TKR2")
  var offersB = @[Offer(base_qty: 1, quote_qty: 1.1)]
  var bookB = Book(market: marketB, offers: offersB)

  var asks = Books(askbid: AskBid.ask, books: @[bookA])
  var bids = Books(askbid: AskBid.bid, books: @[bookB])
  (asks,bids)

proc setup_cross(): (Books, Books) =
  var sourceA = Source(name:"Exchange A")
  var marketA = Market(source: sourceA, base: "TKR1", quote: "TKR2")
  var offersA = @[Offer(base_qty: 1, quote_qty: 1.3)]
  var bookA = Book(market: marketA, offers: offersA)

  var sourceB = Source(name:"Exchange B")
  var marketB = Market(source: sourceB, base: "TKR1", quote: "TKR2")
  var offersB = @[Offer(base_qty: 1, quote_qty: 1.4)]
  var bookB = Book(market: marketB, offers: offersB)

  var asks = Books(askbid: AskBid.ask, books: @[bookA])
  var bids = Books(askbid: AskBid.bid, books: @[bookB])
  (asks,bids)

proc t_1 =
  var (asks,bids) = setup_empty()
  var (askwins, bidwins) = overlap(("TKR1", "TKR2"), asks, bids)
  doAssert 0 == len(askwins.books)
  doAssert 0 == len(bidwins.books)

proc t_2 =
  var (asks,bids) = setup_cross()
  var (askwins, bidwins) = overlap(("TKR1", "TKR2"), asks, bids)
  assert 1 == len(askwins.books)
  assert 1 == len(bidwins.books)

t_1()
t_2()
