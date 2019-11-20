type
  AskBid* = enum ask, bid

  Book* = object
    askbid*: AskBid
    market*: Market
    offers*: seq[Offer]

proc best(book: Book): float =
  book.offers[0].quote_qty