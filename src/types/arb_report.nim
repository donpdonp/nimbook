type ArbReport* = ref object
  id*: string
  date*: string
  pair*: (string, string)
  ask_books*: Books
  bid_books*: Books
  cost*: float
  profit*: float
  profit_usd*: float
  ratio*: float
  fee_eth*: float

proc `$`*(a: ArbReport): string =
  a.id

