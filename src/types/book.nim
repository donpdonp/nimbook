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