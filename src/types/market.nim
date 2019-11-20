type
  Market* = object
    source*: Source
    base*: string
    quote*: string

proc `$`*(m: Market): string =
  m.source.name & ":" & m.base & "/" & m.quote