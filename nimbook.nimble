# Package

version       = "0.1.0"
author        = "donpdonp"
description   = "orderbook juggler"
license       = "MIT"
srcDir        = "src"
bin           = @["main"]
skipDirs      = @["tests"]

# Dependencies
requires "nim >= 1.0.0"
requires "yaml"
requires "https://github.com/donpdonp/libjq-nim"
#requires "redis >= 0.3.0"
