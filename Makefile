.PHONY: all run
.ONESHELL:
.RECIPEPREFIX = =

all: jq
= nim c --threads:on --out:nimbook src/main.nim

run: all
= ./nimbook markets

test:
= nimble test

jq:
= echo building jq
= git clone --depth 1 --recurse-submodules https://github.com/stedolan/jq
= cd jq; autoreconf -fi && ./configure && make
