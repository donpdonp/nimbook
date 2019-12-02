import types
include nimbook, config

proc t_1 =
  var config = load("config.yaml")

  echo "test 1"
  var asks = Books(askbid: AskBid.ask)
  var bids = Books(askbid: AskBid.bid)
  var (askwins, bidwins) = overlap(("TKR1", "TKR2"), asks, bids)
  doAssert 0 == 0

t_1()