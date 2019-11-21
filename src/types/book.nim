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
  b.market.`$` & " " & len(b.offers).`$` & " offers " & (if len(b.offers) > 0:
      b.offers[0].quote_qty.formatFloat(ffDecimal, 4) & " - " & b.offers[high(b.offers)].quote_qty.formatFloat(ffDecimal, 4) else: "")

proc `$`*(bs: Books): string =
  bs.askbid.`$` & " " & bs.books.map(proc (b:Book): string = b.`$`).join(" ")

proc best(book: Book): float =
  book.offers[0].quote_qty