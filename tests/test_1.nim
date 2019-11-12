include nimbook

proc t_1 =
  echo "test 1"
  var asks = @[7,6,5]
  var bids = @[2,3,4]
  var selected = overlap(asks, bids[2])
  doAssert 0 == len(selected)

t_1()