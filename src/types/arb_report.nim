type ArbReport* = ref object
  id*: string
  date*: string
  pair*: (string, string)
  ask_books*: Books
  bid_books*: Books
  cost*: float
  trade_profit*: float
  trade_profit_usd*: float
  profit*: float
  profit_usd*: float
  ratio*: float
  fee_eth*: float

proc `$`*(a: ArbReport): string =
  a.id

