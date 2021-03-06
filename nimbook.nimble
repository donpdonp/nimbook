# Package

version       = "0.2.0"
author        = "donpdonp"
description   = "orderbook juggler"
license       = "MIT"
srcDir        = "src"
bin           = @["nimbook"]
skipDirs      = @["tests"]

# Dependencies
requires "nim >= 1.2.0"
requires "yaml"
requires "https://github.com/donpdonp/libjq-nim >= 0.1.2"
requires "https://github.com/donpdonp/redis#master"
requires "https://github.com/adelq/ulid >= 0.3.0"
requires "ws >= 0.4.0"
