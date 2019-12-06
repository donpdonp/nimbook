import sequtils, strutils

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
  bs.askbid.`$` & " " & bs.books.map(proc (b:Book): string = b.`$`).join(" ")

proc best(book: Book): float =
  book.offers[0].quote_qty

proc offers_better_than*(books: Books, price: float, ticker: Ticker): Books =
  var wins = Books(askbid: books.askbid)
  var offer_filter:proc (o: Offer): bool
  for b in books.books:
    var flipped = ticker != b.market.quote.normal();
    if books.askbid == AskBid.ask:
      offer_filter = proc (o: Offer): bool = o.quote(flipped) < price
    else:
      offer_filter = proc (o: Offer): bool = o.quote(flipped) > price
    let good_offers = b.offers.filter(offer_filter)
    if len(good_offers) > 0:
      wins.books.add(Book(market: b.market, offers: good_offers))
  wins

