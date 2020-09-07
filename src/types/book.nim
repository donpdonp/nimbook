import sequtils, strutils, strformat

type
  AskBid* = enum ask, bid

  Book* = ref object
    market*: Market
    offers*: seq[Offer]

  Books* = ref object
    askbid*: AskBid
    books*: seq[Book]

proc deposit_fee*(book: Book): float =
  0

proc withdrawal_fee*(book: Book): float =
  0

proc fee*(book: Book, gas_price: int): float =
  book.deposit_fee + book.withdrawal_fee

proc best*(book: Book): Offer =
  book.offers[0]

proc close_offer(book: Book, price: float): Offer =
  for offer in book.offers:
    if offer.quote == price:
      return offer
  return nil

proc find_book_by_market*(books: Books, market: Market): Book =
  for bbook in books.books:
    if bbook.market == market:
      return bbook

proc offers_better_than*(books: Books, price: float, ticker: Ticker): Books =
  var wins = Books(askbid: books.askbid)
  for b in books.books:
    if ticker == b.market.quote.normal:
      var offer_filter: proc (o: Offer): bool
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

proc sorted_offers*(books: Books): seq[(Book, Offer)] =
  type ValueMarketOffer = (float, Book, Offer)
  var z = books.books.map(proc (book: Book): seq[ValueMarketOffer] =
    book.offers.map(proc (o: Offer): ValueMarketOffer = (o.quote, book, o)))
  var collection: seq[ValueMarketOffer] = @[]
  for t in z:
    for q in t:
      collection.add(q)
  collection.sort(proc (x, y: ValueMarketOffer): int = cmp(x[0], y[0]),
    if books.askbid == AskBid.ask: Ascending else: Descending)
  let offers = collection.map(proc(e: ValueMarketOffer): (Book, Offer) = (e[1], e[2]))
  offers

proc base_total*(book: Book): float =
  var total = 0f
  for offer in book.offers:
    total += offer.base_qty
  total

proc base_total*(books: Books): float =
  var total = 0f
  for book in books.books:
    total += book.base_total
  total

proc fee*(books: Books, gas_price: int): float =
  var total = 0f
  for book in books.books:
    total += book.fee(gas_price)
  total

proc cost*(book: Book): float =
  var total = 0f
  for offer in book.offers:
    total += offer.base_qty * offer.quote
  total

proc cost*(books: Books): float =
  var total = 0f
  for book in books.books:
    total += book.cost
  total

proc offersummary*(b: Book): string =
  var summary: string = "(empty)"
  let offercount = len(b.offers)
  if offercount > 0:
    let lowidx = low(b.offers)
    let highidx = high(b.offers)
    let lowquote = b.offers[lowidx].`quote$`
    let highquote = b.offers[highidx].`quote$`
    if offercount == 1:
      summary = lowquote
    if offercount == 2:
      summary = "[" & lowquote & ", " & highquote & "]"
    if offercount > 2:
      summary = "(" & lowquote & " - " & highquote & ")/" & offercount.`$`
  summary

proc `$`*(b: Book): string =
  b.market.`$` & " " & b.base_total().formatFloat(ffDecimal, 6) & (
      if b.offers.len > 1: "*" else: "") & "@" & b.offersummary

proc `$`*(bs: Books): string =
  len(bs.books).`$` & " " & bs.askbid.`$` & " books: " & bs.books.map(proc (
      b: Book): string = b.`$`).join(", ")

proc merge*(books: Books, book: Book, offer: Offer) =
  let goodbook = books.find_book_by_market(book.market)
  if goodbook == nil:
    let newbook = Book(market: book.market)
    newbook.offers.add(Offer(base_qty: offer.base_qty, quote: offer.quote))
    books.books.add(newbook)
    #echo &"merge no book found. creating"
  else:
    let closest = goodbook.close_offer(offer.quote)
    if closest == nil:
      #echo &"book found. closest not found"
      goodbook.offers.add(Offer(base_qty: offer.base_qty, quote: offer.quote))
    else:
      closest.base_qty += offer.base_qty

