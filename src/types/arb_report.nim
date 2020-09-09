type ArbReport* = ref object
  id*: string
  date*: string
  pair*: (string, string)
  ask_books*: Books
  bid_books*: Books
  cost*: float
  ratio*: float
  trade_profit*: float
  profit*: float
  fee_network*: float
  quote_usd*: float
  network_usd*: float

proc `$`*(a: ArbReport): string =
  a.id

