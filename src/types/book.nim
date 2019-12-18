import sequtils, strutils, strformat

type
  AskBid* = enum ask, bid

  Book* = object
    market*: Market
    offers*: seq[Offer]

  Books* = object
    askbid*: AskBid
    books*: seq[Book]

proc `$`*(b: Book): string =
  let lowidx = low(b.offers)
  let highidx = high(b.offers)
  b.market.`$` & " " & len(b.offers).`$` & " offers " & (if len(b.offers) > 0:
      b.offers[lowidx].`quote$` &
      " - " &
      b.offers[highidx].`quote$` else: "")

proc `$`*(bs: Books): string =
  len(bs.books).`$` & " " & bs.askbid.`$` & " books: " & bs.books.map(proc (b:Book): string = b.`$`).join(", ")

proc best(book: Book): float =
  book.offers[0].quote

proc offers_better_than*(books: Books, price: float, ticker: Ticker): Books =
  var wins = Books(askbid: books.askbid)
  for b in books.books:
    if ticker == b.market.quote:
      var offer_filter:proc (o: Offer): bool
      if books.askbid == AskBid.ask:
        offer_filter = proc (o: Offer): bool = o.quote < price
      else:
        offer_filter = proc (o: Offer): bool = o.quote > price
      let good_offers = b.offers.filter(offer_filter)
      if len(good_offers) > 0:
        wins.books.add(Book(market: b.market, offers: good_offers))
    else:
      raise newException(OSError, &"offers_better_than got wrong ticker {ticker} for this market {b.market}")
  wins

proc base_total*(books: Books): float =
  var total = 0f
  for book in books.books:
    for offer in book.offers:
      total += offer.base_qty
  total
