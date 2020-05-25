import strformat, strutils

type
  Ticker* = object
    symbol*: string

  TickerSide* = enum Base, Quote

proc `$`*(t: Ticker): string =
  t.symbol

proc normal*(ticker: Ticker): Ticker =
  case ticker.symbol
    of "ETH", "WETH": Ticker(symbol: "eth")
    of "WBTC": Ticker(symbol: "btc")
    of "USDC", "USDT": Ticker(symbol: "usd")
    else: ticker

proc generic_symbol*(ticker: Ticker): string =
  ticker.symbol.split("_")[0]

proc full_name*(ticker: Ticker, contract: string): string =
  let symbol = ticker.symbol
  if contract == "0x0000000000000000000000000000000000000000" or
     contract == "0x000000000000000000000000000000000000000e":
    symbol
  else:
    &"{symbol}_{contract[^6..^1]}" # use 'full name'

proc group_name(ticker: Ticker, contract: string): string =
  let normal = ticker.normal.symbol
  if ticker.symbol == normal: # no generic market
    ticker.full_name(contract)
  else:
    normal

proc `==`*(ticker_a: Ticker, ticker_b: Ticker): bool =
  ticker_a.normal().generic_symbol == ticker_b.normal().generic_symbol

proc other_side*(ticker_side: TickerSide): TickerSide =
  if ticker_side == TickerSide.Base:
    return TickerSide.Quote
  if ticker_side == TickerSide.Quote:
    return TickerSide.Base
