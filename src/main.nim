# nim
import os, strformat
# local
import config, nimbook, types, eth

proc help_closest(word: string) =
  echo word, "not understood"

proc help(config: Config) =
  echo "nimbook markets - find matching markets"
  echo "nimbook book <base> <quote> - compare orderbooks"
  echo "nimbook books - compare all orderbooks"

proc main(args: seq[string]) =
  let config_file = "config.yaml"
  var config = config.load(config_file)
  echo &"nimbook v0.2 ({config_file} loaded)"
  if len(args) > 0:
    case args[0]
      of "markets": nimbook.markets(config)
      of "book":
        var gas_fast = eth.gas_wei()
        book(config, config.marketload(), Ticker(symbol: args[1]),
          Ticker(symbol: args[2]), gas_fast)
      of "books": nimbook.bookall(config, config.marketload())
      else: help(config) #help_closest(args[0])
  else:
    help(config)

proc ctrlc() {.noconv.} =
  quit("ctrl-c")

setControlCHook(ctrlc)

## main
if isMainModule:
  try:
    main(os.commandLineParams())
  except:
    let ex = getCurrentException()
    echo &"isMainModule: {ex.name} : {ex.msg}"
    echo getStackTrace(ex)
