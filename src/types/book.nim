type
  AskBid* = enum ask, bid

  Book* = object
    market*: Market
    offers*: seq[Offer]

  Books* = object
    askbid*: AskBid
    books*: seq[Book]

proc best(book: Book): float =
  book.offers[0].quote_qty