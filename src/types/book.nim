type
  AskBid* = enum ask, bid

  Book* = object
    market*: Market
    offers*: seq[Offer]

  Books* = object
    askbid*: AskBid
    books*: seq[Book]

proc `$`*(b: Book): string =
  b.market.`$` & " " & len(b.offers).`$` & " offers"

proc `$`*(bs: Books): string =
  bs.askbid.`$` & " " & len(bs.books).`$` & " books"

proc best(book: Book): float =
  book.offers[0].quote_qty