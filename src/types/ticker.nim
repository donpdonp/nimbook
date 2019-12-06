type
  Ticker* = object
    symbol*: string

proc `$`*(t: Ticker): string =
  t.symbol

proc normal*(ticker: Ticker): Ticker =
  case ticker.symbol
    of "WETH": Ticker(symbol: "ETH")
    of "WBTC": Ticker(symbol: "BTC")
    of "SAI": Ticker(symbol: "DAI")
    of "USDC", "DAI", "USDT", "TUSD": Ticker(symbol: "USD")
    else: ticker
